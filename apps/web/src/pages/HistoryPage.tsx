import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { RunSummary } from "../api/types";
import { DataTable, type Column } from "../components/DataTable";
import { StatusPill } from "../components/StatusPill";
import styles from "./HistoryPage.module.css";

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

const COLUMNS: Column<RunSummary>[] = [
  { key: "batch_name", header: "Batch name" },
  {
    key: "status",
    header: "Status",
    width: "110px",
    render: (r) => <StatusPill value={r.status} />,
  },
  {
    key: "logger_count",
    header: "Loggers",
    width: "80px",
    render: (r) => <span>{r.logger_count ?? "—"}</span>,
  },
  {
    key: "created_at",
    header: "Created",
    width: "140px",
    render: (r) => <span>{fmt(r.created_at)}</span>,
  },
  {
    key: "completed_at",
    header: "Completed",
    width: "140px",
    render: (r) => <span>{r.completed_at ? fmt(r.completed_at) : "—"}</span>,
  },
];

type ViewMode = "table" | "cards";

export function HistoryPage() {
  const nav = useNavigate();
  const [view, setView] = useState<ViewMode>("table");
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
    refetchInterval: 10_000,
  });

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h2 className={styles.heading}>Calibration History</h2>
        <button className={styles.btnPrimary} onClick={() => nav("/new")}>
          + New calibration
        </button>
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
        <div className={styles.viewToggle}>
          <button className={view === "table" ? styles.active : ""} onClick={() => setView("table")}>
            Table
          </button>
          <button className={view === "cards" ? styles.active : ""} onClick={() => setView("cards")}>
            Cards
          </button>
        </div>
      </div>

      {isLoading ? (
        <p className={styles.empty}>Loading…</p>
      ) : view === "table" ? (
        <DataTable
          columns={COLUMNS}
          rows={data}
          getKey={(r) => r.id}
          onRowClick={(r) => nav(`/calibrations/${r.id}`)}
          emptyMessage="No calibration runs found"
        />
      ) : (
        <div className={styles.cards}>
          {data.length === 0 ? (
            <p className={styles.empty}>No calibration runs found</p>
          ) : (
            data.map((run) => (
              <div key={run.id} className={styles.card} onClick={() => nav(`/calibrations/${run.id}`)}>
                <div className={styles.cardTop}>
                  <span className={styles.cardName}>{run.batch_name}</span>
                  <StatusPill value={run.status} />
                </div>
                <div className={styles.cardMeta}>
                  <span>{run.logger_count != null ? `${run.logger_count} loggers` : "—"}</span>
                  <span>{fmt(run.created_at)}</span>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
