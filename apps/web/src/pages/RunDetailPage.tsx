import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronRight, Download, LayoutGrid, List, RefreshCw } from "lucide-react";
import { useState, useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { LoggerResult, RunDetail } from "../api/types";
import { SortIcon, type SortDir } from "../components/SortIcon";
import { StatusPill } from "../components/StatusPill";
import { useToast } from "../components/Toast";
import styles from "./RunDetailPage.module.css";

type ViewMode = "table" | "cards";
type ResultSortKey = "cert_no" | "sheet_name" | "verdict" | "max_deviation_c";

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function DevBar({ value, withinTol }: { value: number | null; withinTol: boolean }) {
  if (value === null) return <span className={styles.muted}>—</span>;
  const w = Math.min(Math.abs(value) / 2.0 * 80, 80);
  return (
    <div className={styles.devWrap}>
      <div
        className={withinTol ? styles.devBarPass : styles.devBarFail}
        style={{ width: `${w}px` }}
      />
      <span className={withinTol ? styles.devValPass : styles.devValFail}>
        {value.toFixed(2)}
      </span>
    </div>
  );
}

function CertCard({ result, runId }: { result: LoggerResult; runId: string }) {
  const isFail = result.verdict === "fail";
  return (
    <div className={`${styles.card} ${isFail ? styles.cardFail : ""}`}>
      <div className={styles.cardTop}>
        <span className={`${styles.certNo} ${isFail ? styles.certNoFail : ""}`}>
          {result.cert_no ? `No. ${result.cert_no}` : "No cert"}
        </span>
        <StatusPill value={result.verdict} />
      </div>
      <div className={styles.cardLogger}>{result.sheet_name}</div>
      <div className={styles.cardBottom}>
        <span className={`${styles.cardDev} ${isFail ? styles.cardDevFail : ""}`}>
          {result.max_deviation_c !== null ? `${result.max_deviation_c.toFixed(2)}°C max` : "—"}
        </span>
        {result.cert_no && (
          <a
            href={`/api/runs/${runId}/results/${result.id}/certificate`}
            download
            className={styles.dlBtn}
            onClick={(e) => e.stopPropagation()}
            aria-label={`Download certificate ${result.cert_no}`}
          >
            <Download size={12} aria-hidden="true" />
          </a>
        )}
      </div>
    </div>
  );
}

export function RunDetailPage() {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const qc = useQueryClient();
  const { toast } = useToast();
  const [view, setView] = useState<ViewMode>("table");
  const [search, setSearch] = useState("");
  const [verdictFilter, setVerdictFilter] = useState<"" | "pass" | "fail">("");
  const [retrying, setRetrying] = useState(false);

  // Results table sort state
  const [resultSortKey, setResultSortKey] = useState<ResultSortKey>("cert_no");
  const [resultSortDir, setResultSortDir] = useState<SortDir>("asc");

  const { data: run, isLoading, error } = useQuery<RunDetail>({
    queryKey: ["run", id],
    queryFn: () => apiFetch<RunDetail>(`/api/runs/${id}`),
    refetchInterval: (query) => {
      const d = query.state.data as RunDetail | undefined;
      return d?.status === "processing" ? 3000 : false;
    },
  });

  const filtered = useMemo(() => {
    if (!run) return [];
    const q = search.toLowerCase();

    let rows = (run.results ?? []).filter((r) => {
      const matchSearch =
        !q ||
        (r.cert_no?.toLowerCase().includes(q) ?? false) ||
        r.sheet_name.toLowerCase().includes(q);
      const matchVerdict = !verdictFilter || r.verdict === verdictFilter;
      return matchSearch && matchVerdict;
    });

    rows.sort((a, b) => {
      let av: string | number | null, bv: string | number | null;
      if (resultSortKey === "cert_no")         { av = a.cert_no ?? ""; bv = b.cert_no ?? ""; }
      else if (resultSortKey === "sheet_name") { av = a.sheet_name;    bv = b.sheet_name; }
      else if (resultSortKey === "verdict")    { av = a.verdict;        bv = b.verdict; }
      else /* max_deviation_c */               { av = a.max_deviation_c ?? -1; bv = b.max_deviation_c ?? -1; }

      if (av === bv) return 0;
      const cmp = av < bv ? -1 : 1;
      return resultSortDir === "asc" ? cmp : -cmp;
    });

    return rows;
  }, [run, search, verdictFilter, resultSortKey, resultSortDir]);

  const stats = useMemo(() => {
    const results = run?.results ?? [];
    if (!run || results.length === 0) return null;
    const passed = results.filter((r) => r.verdict === "pass").length;
    const failed = results.filter((r) => r.verdict === "fail").length;
    const total = results.length;
    const devs = results
      .map((r) => r.max_deviation_c)
      .filter((d): d is number => d !== null);
    return {
      passed,
      failed,
      passRate: total > 0 ? ((passed / total) * 100).toFixed(1) : null,
      maxDev: devs.length > 0 ? Math.max(...devs).toFixed(2) : null,
    };
  }, [run]);

  function handleResultSort(key: ResultSortKey) {
    if (resultSortKey === key) {
      setResultSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setResultSortKey(key);
      setResultSortDir("asc");
    }
  }

  const thSortProps = (key: ResultSortKey) => ({
    className: `${styles.thSort} ${resultSortKey === key ? styles.thSortActive : ""}`,
    onClick: () => handleResultSort(key),
    "aria-sort": (resultSortKey === key
      ? resultSortDir === "asc" ? "ascending" : "descending"
      : "none") as React.AriaAttributes["aria-sort"],
  });

  async function handleRetry() {
    if (!id) return;
    setRetrying(true);
    try {
      await apiFetch(`/api/runs/${id}/process`, { method: "POST" });
      qc.invalidateQueries({ queryKey: ["run", id] });
      toast("Processing restarted", "success");
    } catch {
      toast("Failed to retry processing", "error");
    } finally {
      setRetrying(false);
    }
  }

  if (isLoading) return <div className={styles.loading}>Loading…</div>;
  if (error || !run) return <div className={styles.loading}>Run not found.</div>;

  return (
    <div className={styles.page}>
      {/* ── Breadcrumb ── */}
      <nav aria-label="Breadcrumb" className={styles.breadcrumb}>
        <button className={styles.breadcrumbLink} onClick={() => nav("/calibrations")}>
          Calibrations
        </button>
        <ChevronRight size={13} className={styles.breadcrumbSep} aria-hidden="true" />
        <span className={styles.breadcrumbCurrent}>{run.batch_name}</span>
      </nav>

      {/* ── Header ── */}
      <div className={styles.header}>
        <div className={styles.headerRow}>
          <div className={styles.headerLeft}>
            <h2 className={styles.heading}>{run.batch_name}</h2>
            <div className={styles.headMeta}>
              <StatusPill value={run.status} />
              <span className={styles.metaDot}>·</span>
              <span className={styles.metaText}>{fmt(run.created_at)}</span>
              {run.results.length > 0 && (
                <>
                  <span className={styles.metaDot}>·</span>
                  <span className={styles.metaText}>{run.results.length} loggers</span>
                </>
              )}
            </div>
          </div>
          {run.status === "complete" && (
            <a
              href={`/api/runs/${id}/results.zip`}
              download
              className={styles.btnPrimary}
              aria-label="Download all certificates as ZIP"
            >
              <Download size={14} aria-hidden="true" />
              Download all (.zip)
            </a>
          )}
        </div>
      </div>

      {/* ── Config strip (always visible, below header) ── */}
      <div className={styles.configStrip}>
        <div className={styles.configItem}>
          <span className={styles.configLabel}>Test date</span>
          <span className={styles.configVal}>{run.test_date_jp}</span>
        </div>
        <div className={styles.configDivider} />
        <div className={styles.configItem}>
          <span className={styles.configLabel}>Cert date</span>
          <span className={styles.configVal}>{run.doc_date_jp}</span>
        </div>
        <div className={styles.configDivider} />
        <div className={styles.configItem}>
          <span className={styles.configLabel}>Threshold</span>
          <span className={styles.configVal}>±{run.threshold_c}°C</span>
        </div>
        <div className={styles.configDivider} />
        <div className={styles.configItem}>
          <span className={styles.configLabel}>Start cert no.</span>
          <span className={styles.configVal}>{run.start_cert_no}</span>
        </div>
        <div className={styles.configDivider} />
        <div className={styles.configItem}>
          <span className={styles.configLabel}>Setpoints</span>
          <div className={styles.setpointChips}>
            {run.setpoints.map((sp: { target_c: number }) => (
              <span key={sp.target_c} className={styles.setpointChip}>
                {sp.target_c > 0 ? "+" : ""}{sp.target_c}°C
              </span>
            ))}
          </div>
        </div>
        {(run.reference_files.length > 0 || run.calibration_file) && (
          <>
            <div className={styles.configDivider} />
            <div className={styles.configItem}>
              <span className={styles.configLabel}>Files</span>
              <span className={styles.configVal}>
                {[
                  ...run.reference_files.map((f) => f.original_name),
                  run.calibration_file?.original_name,
                ]
                  .filter(Boolean)
                  .join(", ")}
              </span>
            </div>
          </>
        )}
      </div>

      {run.failure_reason && (
        <div className={styles.errorBanner}>
          <span>{run.failure_reason.message ?? "Processing failed"}</span>
          <button
            className={styles.retryBtn}
            onClick={handleRetry}
            disabled={retrying}
            aria-label="Retry processing"
          >
            <RefreshCw size={13} aria-hidden="true" />
            {retrying ? "Retrying…" : "Retry"}
          </button>
        </div>
      )}

      {/* ── Stat strip ── */}
      {stats && (
        <div className={styles.statStrip}>
          <div className={styles.statItem}>
            <span className={`${styles.statVal} ${styles.statPass}`}>{stats.passed}</span>
            <span className={styles.statLbl}>Pass</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={`${styles.statVal} ${stats.failed > 0 ? styles.statFail : ""}`}>{stats.failed}</span>
            <span className={styles.statLbl}>Fail</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={styles.statVal}>{stats.passRate ?? "—"}%</span>
            <span className={styles.statLbl}>Pass rate</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={styles.statVal}>{stats.maxDev ? `${stats.maxDev}°C` : "—"}</span>
            <span className={styles.statLbl}>Max dev.</span>
          </div>
        </div>
      )}

      {/* ── Toolbar ── */}
      <div className={styles.toolbar}>
        <input
          className={styles.search}
          placeholder="Search cert no. or logger serial…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button
          className={`${styles.filterPill} ${verdictFilter === "" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("")}
        >All</button>
        <button
          className={`${styles.filterPill} ${verdictFilter === "pass" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("pass")}
        >Pass</button>
        <button
          className={`${styles.filterPill} ${verdictFilter === "fail" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("fail")}
        >Fail</button>
        <div className={styles.viewToggle}>
          <button
            className={`${styles.vtBtn} ${view === "table" ? styles.vtActive : ""}`}
            onClick={() => setView("table")}
            aria-label="Table view"
            aria-pressed={view === "table"}
          >
            <List size={14} aria-hidden="true" /> Table
          </button>
          <button
            className={`${styles.vtBtn} ${view === "cards" ? styles.vtActive : ""}`}
            onClick={() => setView("cards")}
            aria-label="Cards view"
            aria-pressed={view === "cards"}
          >
            <LayoutGrid size={14} aria-hidden="true" /> Cards
          </button>
        </div>
      </div>

      {/* ── Content: table or cards ── */}
      <div className={styles.viewArea}>
        {run.results.length === 0 ? (
          <p className={styles.empty}>No results yet.</p>
        ) : view === "table" ? (
          <div key="table" className={`${styles.tableWrap} ${styles.viewIn}`}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th {...thSortProps("cert_no")}>
                    Cert no.{" "}
                    <SortIcon active={resultSortKey === "cert_no"} dir={resultSortDir} className={styles.sortIconInactive} />
                  </th>
                  <th {...thSortProps("sheet_name")}>
                    Logger serial{" "}
                    <SortIcon active={resultSortKey === "sheet_name"} dir={resultSortDir} className={styles.sortIconInactive} />
                  </th>
                  <th {...thSortProps("verdict")}>
                    Verdict{" "}
                    <SortIcon active={resultSortKey === "verdict"} dir={resultSortDir} className={styles.sortIconInactive} />
                  </th>
                  {run.results[0]?.per_setpoint.map((sp) => (
                    <th key={sp.target_c}>{sp.target_c > 0 ? "+" : ""}{sp.target_c}°C</th>
                  ))}
                  <th {...thSortProps("max_deviation_c")}>
                    Max dev.{" "}
                    <SortIcon active={resultSortKey === "max_deviation_c"} dir={resultSortDir} className={styles.sortIconInactive} />
                  </th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr><td colSpan={5 + (run.results[0]?.per_setpoint.length ?? 0)} className={styles.empty}>No results match</td></tr>
                ) : (
                  filtered.map((r) => (
                    <tr key={r.id} className={r.verdict === "fail" ? styles.rowFail : styles.rowPass}>
                      <td className={`${styles.certNoCell} ${r.verdict === "fail" ? styles.certNoFail : ""}`}>
                        {r.cert_no ?? "—"}
                      </td>
                      <td className={styles.serialCell}>{r.sheet_name}</td>
                      <td><StatusPill value={r.verdict} /></td>
                      {r.per_setpoint.map((sp) => (
                        <td key={sp.target_c}>
                          <DevBar value={sp.dev_c} withinTol={sp.within_tol} />
                        </td>
                      ))}
                      <td className={r.verdict === "fail" ? styles.devValFail : styles.devValPass}>
                        {r.max_deviation_c !== null ? `${r.max_deviation_c.toFixed(2)}°C` : "—"}
                      </td>
                      <td>
                        {r.cert_no && (
                          <a
                            href={`/api/runs/${id}/results/${r.id}/certificate`}
                            download
                            className={styles.dlBtn}
                            aria-label={`Download certificate ${r.cert_no}`}
                          >
                            <Download size={12} aria-hidden="true" />
                          </a>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        ) : (
          <div key="cards" className={`${styles.cardGrid} ${styles.viewIn}`}>
            {filtered.length === 0 ? (
              <p className={styles.empty}>No results match</p>
            ) : (
              filtered.map((r) => <CertCard key={r.id} result={r} runId={id!} />)
            )}
          </div>
        )}
      </div>
    </div>
  );
}
