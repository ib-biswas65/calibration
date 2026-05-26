import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { RunDetail } from "../api/types";
import { StatusPill } from "../components/StatusPill";
import styles from "./RunDetailPage.module.css";

type Tab = "loggers" | "setpoints" | "conditions" | "audit";

function fmt(dt: string) {
  return new Date(dt).toLocaleString("en-GB", {
    day: "2-digit", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}

export function RunDetailPage() {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const [tab, setTab] = useState<Tab>("loggers");

  const { data: run, isLoading, error } = useQuery<RunDetail>({
    queryKey: ["run", id],
    queryFn: () => apiFetch<RunDetail>(`/api/runs/${id}`),
    refetchInterval: (query) => {
      const d = query.state.data as RunDetail | undefined;
      return d?.status === "processing" ? 3000 : false;
    },
  });

  if (isLoading) return <div className={styles.loading}>Loading…</div>;
  if (error || !run) return <div className={styles.loading}>Run not found.</div>;

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <button className={styles.back} onClick={() => nav("/calibrations")}>← History</button>
        <div className={styles.headerMain}>
          <h2 className={styles.heading}>{run.batch_name}</h2>
          <StatusPill value={run.status} />
        </div>
        {run.status === "complete" && (
          <a href={`/api/runs/${id}/results.zip`} download className={styles.btnPrimary}>
            Download all (.zip)
          </a>
        )}
      </div>

      {run.failure_reason && (
        <div className={styles.errorBanner}>
          {run.failure_reason.message ?? "Processing failed"}
        </div>
      )}

      <div className={styles.tabs}>
        {(["loggers", "setpoints", "conditions", "audit"] as Tab[]).map((t) => (
          <button key={t} className={`${styles.tab} ${tab === t ? styles.activeTab : ""}`} onClick={() => setTab(t)}>
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {tab === "loggers" && (
        <div className={styles.tabContent}>
          {run.results.length === 0 ? (
            <p className={styles.empty}>No results yet.</p>
          ) : (
            <table className={styles.resultsTable}>
              <thead>
                <tr>
                  <th>Serial / Sheet</th>
                  <th>Verdict</th>
                  <th>Max dev. (°C)</th>
                  <th>Cert no.</th>
                  {run.results[0]?.per_setpoint.map((sp) => (
                    <th key={sp.target_c}>{sp.target_c > 0 ? "+" : ""}{sp.target_c}°C</th>
                  ))}
                  <th>Download</th>
                </tr>
              </thead>
              <tbody>
                {run.results.map((r) => (
                  <tr key={r.id}>
                    <td className={styles.serial}>{r.sheet_name}</td>
                    <td><StatusPill value={r.verdict} /></td>
                    <td>{r.max_deviation_c != null ? r.max_deviation_c.toFixed(3) : "—"}</td>
                    <td>{r.cert_no ?? "—"}</td>
                    {r.per_setpoint.map((sp) => (
                      <td key={sp.target_c} className={sp.within_tol ? styles.cellPass : styles.cellFail}>
                        {sp.dev_c != null ? sp.dev_c.toFixed(3) : "—"}
                      </td>
                    ))}
                    <td>
                      {run.status === "complete" && (
                        <a href={`/api/runs/${id}/results/${r.id}/certificate`} download className={styles.dlLink}>
                          .docx
                        </a>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {tab === "setpoints" && (
        <div className={styles.tabContent}>
          <table className={styles.simpleTable}>
            <thead>
              <tr><th>Target (°C)</th><th>Window start</th><th>Window end</th></tr>
            </thead>
            <tbody>
              {run.setpoints.map((sp) => (
                <tr key={sp.target_c}>
                  <td>{sp.target_c > 0 ? "+" : ""}{sp.target_c}°C</td>
                  <td>{fmt(sp.start_at)}</td>
                  <td>{fmt(sp.end_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className={styles.metaRow}>
            <span><strong>Threshold:</strong> ±{run.threshold_c}°C</span>
            <span><strong>Testing:</strong> {fmt(run.testing_start)} → {fmt(run.testing_end)}</span>
          </div>
        </div>
      )}

      {tab === "conditions" && (
        <div className={styles.tabContent}>
          <h4 className={styles.subHeading}>Reference files</h4>
          {run.reference_files.length === 0 ? (
            <p className={styles.empty}>No reference files.</p>
          ) : (
            <ul className={styles.fileList}>
              {run.reference_files.map((f) => (
                <li key={f.id}>
                  <span className={styles.fileName}>{f.original_name}</span>
                  <code className={styles.sha}>{f.sha256.slice(0, 12)}…</code>
                </li>
              ))}
            </ul>
          )}
          <h4 className={styles.subHeading}>Calibration workbook</h4>
          {run.calibration_file ? (
            <ul className={styles.fileList}>
              <li>
                <span className={styles.fileName}>{run.calibration_file.original_name}</span>
                <code className={styles.sha}>{run.calibration_file.sha256.slice(0, 12)}…</code>
              </li>
            </ul>
          ) : (
            <p className={styles.empty}>No workbook uploaded.</p>
          )}
        </div>
      )}

      {tab === "audit" && (
        <div className={styles.tabContent}>
          <AuditTrail runId={id!} />
        </div>
      )}
    </div>
  );
}

function AuditTrail({ runId }: { runId: string }) {
  const { data = [], isLoading } = useQuery<{ action: string; at: string; detail: unknown }[]>({
    queryKey: ["audit", runId],
    queryFn: () => apiFetch(`/api/runs/${runId}/audit`),
    retry: false,
  });

  if (isLoading) return <p>Loading…</p>;

  return (
    <ul className={styles.auditList}>
      {data.length === 0 ? (
        <li className={styles.empty}>No audit entries.</li>
      ) : (
        data.map((entry, i) => (
          <li key={i} className={styles.auditEntry}>
            <code className={styles.auditAction}>{entry.action}</code>
            <span className={styles.auditAt}>{new Date(entry.at).toLocaleString("en-GB")}</span>
          </li>
        ))
      )}
    </ul>
  );
}
