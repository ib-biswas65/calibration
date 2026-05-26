import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";

import { apiFetch } from "../api/client";
import { LoggerSummary } from "../api/types";
import { DataTable } from "../components/DataTable";
import { StatusPill } from "../components/StatusPill";
import styles from "./LoggersPage.module.css";

interface LoggerHistory {
  result_id: string;
  run_id: string;
  verdict: string;
  max_deviation_c: number | null;
  cert_no: string | null;
  created_at: string;
}

interface LoggerDetail extends LoggerSummary {
  history: LoggerHistory[];
}

function dueLabel(isoDate: string | null): { text: string; cls: string } {
  if (!isoDate) return { text: "—", cls: styles.due };
  const days = Math.ceil((new Date(isoDate).getTime() - Date.now()) / 86_400_000);
  if (days < 0) return { text: `Overdue (${-days}d)`, cls: styles.dueOverdue };
  if (days <= 30) return { text: `Due in ${days}d`, cls: styles.dueWarn };
  return { text: new Date(isoDate).toLocaleDateString(), cls: styles.due };
}

export function LoggersPage() {
  const nav = useNavigate();
  const [q, setQ] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { data: loggers = [], isLoading } = useQuery<LoggerSummary[]>({
    queryKey: ["loggers", q],
    queryFn: () => apiFetch(`/api/loggers?q=${encodeURIComponent(q)}&limit=100`),
  });

  const { data: detail } = useQuery<LoggerDetail>({
    queryKey: ["logger", selectedId],
    queryFn: () => apiFetch(`/api/loggers/${selectedId}`),
    enabled: !!selectedId,
  });

  const cols = [
    { key: "serial_no" as const, header: "Serial No." },
    { key: "model" as const, header: "Model", render: (lg: LoggerSummary) => lg.model ?? "—" },
    {
      key: "next_due_at" as const,
      header: "Next due",
      render: (lg: LoggerSummary) => {
        const { text, cls } = dueLabel(lg.next_due_at);
        return <span className={cls}>{text}</span>;
      },
    },
    { key: "notes" as const, header: "Notes", render: (lg: LoggerSummary) => lg.notes ?? "—" },
  ];

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h1 className={styles.title}>Logger fleet</h1>
        <input
          className={styles.search}
          placeholder="Search serial…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      <DataTable
        columns={cols}
        rows={loggers}
        getKey={(lg) => lg.id}
        onRowClick={(lg) => setSelectedId(lg.id === selectedId ? null : lg.id)}
        emptyMessage={isLoading ? "Loading…" : "No loggers found."}
      />

      {selectedId && detail && (
        <div className={styles.detail}>
          <div className={styles.detailHeader}>
            <h2 className={styles.detailTitle}>{detail.serial_no}</h2>
            <button className={styles.closeBtn} onClick={() => setSelectedId(null)}>Close</button>
          </div>

          <div className={styles.meta}>
            <div className={styles.metaItem}>
              <strong>Model</strong>{detail.model ?? "—"}
            </div>
            <div className={styles.metaItem}>
              <strong>Next due</strong>
              {(() => { const { text, cls } = dueLabel(detail.next_due_at); return <span className={cls}>{text}</span>; })()}
            </div>
            {detail.notes && (
              <div className={styles.metaItem}>
                <strong>Notes</strong>{detail.notes}
              </div>
            )}
          </div>

          <p className={styles.historyTitle}>Calibration history (last 20)</p>
          {detail.history.length === 0 ? (
            <p className={styles.empty}>No calibration history yet.</p>
          ) : (
            <DataTable
              columns={[
                { key: "created_at", header: "Date", render: (r: LoggerHistory) => new Date(r.created_at).toLocaleDateString() },
                { key: "verdict", header: "Verdict", render: (r: LoggerHistory) => <StatusPill value={r.verdict} /> },
                { key: "max_deviation_c", header: "Max Δ°C", render: (r: LoggerHistory) => r.max_deviation_c != null ? r.max_deviation_c.toFixed(3) : "—" },
                { key: "cert_no", header: "Cert No.", render: (r: LoggerHistory) => r.cert_no ?? "—" },
              ]}
              rows={detail.history}
              getKey={(r) => r.result_id}
              onRowClick={(r) => nav(`/calibrations/${r.run_id}`)}
              emptyMessage="No history."
            />
          )}
        </div>
      )}
    </div>
  );
}
