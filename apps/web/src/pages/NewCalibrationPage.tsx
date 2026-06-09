import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ApiError, apiFetch } from "../api/client";
import type { CalibrationUploadResponse, FileUploadResponse, RunDetail } from "../api/types";
import { FileDropZone } from "../components/FileDropZone";
import { SetpointWindowRow, type SetpointValue } from "../components/SetpointWindowRow";
import { useToast } from "../components/Toast";
import styles from "./NewCalibrationPage.module.css";

const DEFAULT_SETPOINTS: SetpointValue[] = [
  { target_c: -40, start_at: "1900-01-01T00:00:00Z", end_at: "2999-12-31T23:59:00Z" },
  { target_c: 5,   start_at: "1900-01-01T00:00:00Z", end_at: "2999-12-31T23:59:00Z" },
  { target_c: 40,  start_at: "1900-01-01T00:00:00Z", end_at: "2999-12-31T23:59:00Z" },
];

function today() {
  return new Date().toISOString().slice(0, 10);
}

function jpDate(d: string) {
  const dt = new Date(d);
  return `${dt.getFullYear()}年${dt.getMonth() + 1}月${dt.getDate()}日`;
}

export function NewCalibrationPage() {
  const nav = useNavigate();
  const qc = useQueryClient();
  const { toast } = useToast();

  // Form state
  const [batchName, setBatchName] = useState("");
  const [testingStart, setTestingStart] = useState("");
  const [testingEnd, setTestingEnd] = useState("");
  const [certDate, setCertDate] = useState(today());
  const [threshold, setThreshold] = useState("0.5");
  const [startCertNo, setStartCertNo] = useState("0000001000");
  const [certWidth, setCertWidth] = useState("10");
  const [setpoints, setSetpoints] = useState<SetpointValue[]>(DEFAULT_SETPOINTS);

  // Run state (created after form submit)
  const [runId, setRunId] = useState<string | null>(null);
  const [refFiles, setRefFiles] = useState<Array<{ name: string; id: string }>>([]);
  const [calFile, setCalFile] = useState<{ name: string; sheets: string[] } | null>(null);
  const [phase, setPhase] = useState<"form" | "files" | "processing" | "done">("form");

  // Processing polling
  const { data: statusData } = useQuery<{ status: string; message: string | null }>({
    queryKey: ["run-status", runId],
    queryFn: () => apiFetch(`/api/runs/${runId}/status`),
    enabled: !!runId && phase === "processing",
    refetchInterval: 4000,
  });

  useEffect(() => {
    if (statusData?.status === "complete") {
      setPhase("done");
      qc.invalidateQueries({ queryKey: ["runs"] });
      qc.invalidateQueries({ queryKey: ["overview"] });
      toast("Certificates generated!", "success");
    } else if (statusData?.status === "failed") {
      setPhase("files");
      toast(statusData.message ?? "Processing failed", "error");
    }
  }, [statusData, qc, toast]);

  async function handleCreateRun(e: React.FormEvent) {
    e.preventDefault();

    const invalidSp = setpoints.find((sp) => sp.start_at >= sp.end_at);
    if (invalidSp) {
      toast(`Setpoint ${invalidSp.target_c}°C: end time must be after start time`, "error");
      return;
    }
    if (testingStart && testingEnd && testingStart >= testingEnd) {
      toast("Testing end must be after testing start", "error");
      return;
    }

    try {
      const run = await apiFetch<RunDetail>("/api/runs", {
        method: "POST",
        json: {
          batch_name: batchName.trim().normalize("NFC"),
          testing_start: testingStart ? testingStart + ":00Z" : new Date().toISOString(),
          testing_end: testingEnd ? testingEnd + ":00Z" : new Date().toISOString(),
          certificate_date: certDate,
          threshold_c: parseFloat(threshold),
          setpoints: setpoints.map((sp) => ({
            target_c: sp.target_c,
            start_at: sp.start_at,
            end_at: sp.end_at,
          })),
          start_cert_no: startCertNo,
          cert_width: parseInt(certWidth),
          test_date_jp: testingStart ? jpDate(testingStart) : jpDate(certDate),
          doc_date_jp: jpDate(certDate),
        },
      });
      setRunId(run.id);
      setPhase("files");
    } catch (err) {
      toast(err instanceof ApiError ? String(err.status) : "Failed to create run", "error");
    }
  }

  async function handleRefUpload(files: File[]) {
    if (!runId) return;
    for (const file of files) {
      const fd = new FormData();
      fd.append("file", file);
      try {
        const res = await apiFetch<FileUploadResponse>(`/api/runs/${runId}/references`, {
          method: "POST",
          body: fd,
        });
        setRefFiles((prev) => [...prev, { name: file.name, id: res.file_id }]);
        toast(`Uploaded ${file.name}`, "success");
      } catch {
        toast(`Failed to upload ${file.name}`, "error");
      }
    }
  }

  async function handleCalUpload(files: File[]) {
    if (!runId || !files[0]) return;
    const file = files[0];
    const fd = new FormData();
    fd.append("file", file);
    try {
      const res = await apiFetch<CalibrationUploadResponse>(`/api/runs/${runId}/calibration`, {
        method: "POST",
        body: fd,
      });
      setCalFile({ name: file.name, sheets: res.sheet_names });
      toast(`Workbook uploaded — ${res.sheet_names.length} sheet(s)`, "success");
    } catch {
      toast("Failed to upload workbook", "error");
    }
  }

  async function handleProcess() {
    if (!runId) return;
    try {
      await apiFetch(`/api/runs/${runId}/process`, { method: "POST" });
      setPhase("processing");
    } catch (err) {
      toast(err instanceof ApiError ? String(err.detail) : "Failed to start", "error");
    }
  }

  const STEPS = [
    { key: "form", label: "Configure" },
    { key: "files", label: "Upload" },
    { key: "processing", label: "Process" },
    { key: "done", label: "Done" },
  ];
  const currentStep = STEPS.findIndex((s) => s.key === phase);

  function stepClass(idx: number) {
    if (idx < currentStep) return `${styles.step} ${styles.stepDone}`;
    if (idx === currentStep) return `${styles.step} ${styles.stepActive}`;
    return styles.step;
  }

  if (phase === "done" && runId) {
    return (
      <div className={styles.page}>
        <div className={styles.done}>
          <h2>Certificates ready</h2>
          <p>All calibration certificates have been generated.</p>
          <div className={styles.doneActions}>
            <a href={`/api/runs/${runId}/results.zip`} className={styles.btnPrimary} download>
              Download all (.zip)
            </a>
            <button className={styles.btnSecondary} onClick={() => nav(`/calibrations/${runId}`)}>
              View run detail
            </button>
          </div>
        </div>
      </div>
    );
  }

  const infoPanel = (
    <aside className={styles.infoPanel}>
      <span className={styles.infoPanelTitle}>How it works</span>

      <div className={styles.infoStep}>
        <span className={styles.infoStepNum}>1</span>
        <div className={styles.infoStepBody}>
          <span className={styles.infoStepLabel}>Configure the batch</span>
          <span className={styles.infoStepDesc}>Set the batch name, certificate date, testing window, and setpoint time ranges.</span>
        </div>
      </div>
      <div className={styles.infoStep}>
        <span className={styles.infoStepNum}>2</span>
        <div className={styles.infoStepBody}>
          <span className={styles.infoStepLabel}>Upload reference data</span>
          <span className={styles.infoStepDesc}>One CSV per reference logger. Multiple files are automatically merged.</span>
        </div>
      </div>
      <div className={styles.infoStep}>
        <span className={styles.infoStepNum}>3</span>
        <div className={styles.infoStepBody}>
          <span className={styles.infoStepLabel}>Upload calibration workbook</span>
          <span className={styles.infoStepDesc}>One XLSX with a sheet per logger. Each sheet name becomes the logger serial number.</span>
        </div>
      </div>
      <div className={styles.infoStep}>
        <span className={styles.infoStepNum}>4</span>
        <div className={styles.infoStepBody}>
          <span className={styles.infoStepLabel}>Generate certificates</span>
          <span className={styles.infoStepDesc}>The engine matches readings, calculates deviation, and fills the certificate template.</span>
        </div>
      </div>

      <hr className={styles.infoDivider} />

      <div className={styles.infoNote}>
        <span className={styles.infoNoteLabel}>Cert no. width</span>
        Controls zero-padding. Width 10 with start 1000 produces <code>0000001000</code>.
      </div>
      <div className={styles.infoNote}>
        <span className={styles.infoNoteLabel}>Threshold</span>
        Maximum allowed deviation in °C. Results exceeding this are marked as fail.
      </div>
    </aside>
  );

  return (
    <div className={styles.page}>
      <h2 className={styles.heading}>New Calibration</h2>

      {/* ── Progress steps ── */}
      <div className={styles.steps} aria-label="Progress">
        {STEPS.map((s, i) => (
          <div key={s.key} style={{ display: "contents" }}>
            <div className={stepClass(i)}>
              <span className={styles.stepNum}>{i + 1}</span>
              <span className={styles.stepLabel}>{s.label}</span>
            </div>
            {i < STEPS.length - 1 && <div className={styles.stepConnector} aria-hidden="true" />}
          </div>
        ))}
      </div>

      {phase === "form" && (
        <div className={styles.layout}>
          <form className={styles.form} onSubmit={handleCreateRun}>
            <section className={styles.section}>
              <h3 className={styles.sectionTitle}>Batch info</h3>
              <div className={styles.fieldGrid}>
                <label className={styles.field}>
                  <span>Batch name</span>
                  <input required value={batchName} onChange={(e) => setBatchName(e.target.value)}
                    placeholder="e.g. April 2026 — Batch 1" />
                </label>
                <label className={styles.field}>
                  <span>Certificate date</span>
                  <input type="date" required value={certDate} onChange={(e) => setCertDate(e.target.value)} />
                </label>
                <label className={styles.field}>
                  <span>Testing start</span>
                  <input type="datetime-local" required value={testingStart} onChange={(e) => setTestingStart(e.target.value)} />
                </label>
                <label className={styles.field}>
                  <span>Testing end</span>
                  <input type="datetime-local" required value={testingEnd} onChange={(e) => setTestingEnd(e.target.value)} />
                </label>
                <label className={styles.field}>
                  <span>Starting cert no.</span>
                  <input required value={startCertNo} onChange={(e) => setStartCertNo(e.target.value)} />
                </label>
                <label className={styles.field}>
                  <span>Cert no. width</span>
                  <input type="number" min={1} max={20} value={certWidth} onChange={(e) => setCertWidth(e.target.value)} />
                </label>
                <label className={styles.field}>
                  <span>Threshold (°C)</span>
                  <input type="number" step="0.01" value={threshold} onChange={(e) => setThreshold(e.target.value)} />
                </label>
              </div>
            </section>

            <section className={styles.section}>
              <h3 className={styles.sectionTitle}>Setpoint windows</h3>
              <div className={styles.setpoints}>
                {setpoints.map((sp, i) => (
                  <SetpointWindowRow
                    key={sp.target_c}
                    value={sp}
                    onChange={(v) => setSetpoints((prev) => prev.map((s, j) => j === i ? v : s))}
                  />
                ))}
              </div>
            </section>

            <button type="submit" className={styles.btnPrimary}>Continue — Upload files</button>
          </form>
          {infoPanel}
        </div>
      )}

      {(phase === "files" || phase === "processing") && (
        <div className={styles.layout}>
          <div className={styles.files}>
            <section className={styles.section}>
              <h3 className={styles.sectionTitle}>Reference loggers</h3>
              <FileDropZone
                label="Drop reference CSV(s) here or click to browse"
                accept=".csv"
                multiple
                onFiles={handleRefUpload}
                hint="Multiple files allowed — one per reference logger"
              />
              {refFiles.length > 0 && (
                <ul className={styles.fileList}>
                  {refFiles.map((f) => <li key={f.id}>{f.name}</li>)}
                </ul>
              )}
            </section>

            <section className={styles.section}>
              <h3 className={styles.sectionTitle}>Calibration workbook</h3>
              <FileDropZone
                label="Drop calibration XLSX here or click to browse"
                accept=".xlsx"
                onFiles={handleCalUpload}
                hint="One file — each sheet = one logger"
              />
              {calFile && (
                <div className={styles.calInfo}>
                  <strong>{calFile.name}</strong>
                  <span> — {calFile.sheets.length} sheet(s): {calFile.sheets.slice(0, 5).join(", ")}
                    {calFile.sheets.length > 5 ? ` … +${calFile.sheets.length - 5} more` : ""}
                  </span>
                </div>
              )}
            </section>

            {/* CrossFade: button fades out as spinner fades in (300ms) */}
            <div className={styles.processWrap}>
              {phase === "processing" ? (
                <div className={styles.progress}>
                  <span className={styles.spinner} />
                  Processing… {statusData?.message ?? ""}
                </div>
              ) : (
                <button
                  className={styles.btnPrimary}
                  style={{ animation: "fadeIn 300ms var(--ease-out) both" }}
                  disabled={refFiles.length === 0 || !calFile}
                  onClick={handleProcess}
                >
                  Generate certificates
                </button>
              )}
            </div>
          </div>
          {infoPanel}
        </div>
      )}
    </div>
  );
}
