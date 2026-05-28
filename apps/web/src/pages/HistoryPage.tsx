import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { RunSummary } from "../api/types";
import { StatusPill } from "../components/StatusPill";
import styles from "./HistoryPage.module.css";

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function PassRateBar({ rate }: { rate: number | null }) {
  if (rate === null) return <span className={styles.muted}>—</span>;
  const pass = Math.round(rate);
  const fail = 100 - pass;
  return (
    <div className={styles.rateWrap}>
      <div className={styles.sparkBar}>
        <div className={styles.sparkPass} style={{ width: `${pass}%` }} />
        <div className={styles.sparkFail} style={{ width: `${fail}%` }} />
      </div>
      <span className={styles.rateVal}>{rate.toFixed(1)}%</span>
    </div>
  );
}

export function HistoryPage() {
  const nav = useNavigate();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  const { data = [], isLoading } = useQuery<RunSummary[]>({
    queryKey: ["runs", search, statusFilter],
    queryFn: () => {
      const params = new URLSearchParams();
      if (search) params.set("q", search);
      if (statusFilter) params.set("status", statusFilter);
      return apiFetch<RunSummary[]>(`/api/runs?${params}`);
    },
    refetchInterval: 30_000,
  });

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h2 className={styles.heading}>Calibration History</h2>
        <button className={styles.btnPrimary} onClick={() => nav("/new")}>+ New calibration</button>
      </div>

      <div className={styles.toolbar}>
        <input
          className={styles.search}
          placeholder="Search batch name…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select className={styles.select} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="">All statuses</option>
          <option value="draft">Draft</option>
          <option value="processing">Processing</option>
          <option value="complete">Complete</option>
          <option value="failed">Failed</option>
        </select>
      </div>

      {isLoading ? (
        <p className={styles.empty}>Loading…</p>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Batch name</th>
                <th>Status</th>
                <th className={styles.colNum}>Loggers</th>
                <th className={styles.colWide}>Pass rate</th>
                <th className={styles.colNum}>Max dev.</th>
                <th className={styles.colNum}>Date</th>
              </tr>
            </thead>
            <tbody>
              {data.length === 0 ? (
                <tr>
                  <td colSpan={6} className={styles.empty}>No calibration runs found</td>
                </tr>
              ) : (
                data.map((run) => (
                  <tr key={run.id} className={styles.row} onClick={() => nav(`/calibrations/${run.id}`)}>
                    <td className={styles.nameCell}>{run.batch_name}</td>
                    <td><StatusPill value={run.status} /></td>
                    <td className={styles.numCell}>{run.logger_count ?? "—"}</td>
                    <td><PassRateBar rate={run.pass_rate} /></td>
                    <td className={styles.numCell}>
                      {run.max_deviation_c !== null && run.max_deviation_c !== undefined
                        ? <span className={run.max_deviation_c > 0.5 ? styles.devFail : styles.devOk}>
                            {run.max_deviation_c.toFixed(1)}°C
                          </span>
                        : <span className={styles.muted}>—</span>}
                    </td>
                    <td className={styles.numCell}>{fmt(run.created_at)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
