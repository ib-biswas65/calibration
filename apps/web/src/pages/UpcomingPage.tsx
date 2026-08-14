import { useQuery } from "@tanstack/react-query";

import { apiFetch } from "../api/client";
import { LoggerSummary } from "../api/types";
import { DataTable } from "../components/DataTable";
import styles from "./LoggersPage.module.css";

function daysUntil(isoDate: string): number {
  return Math.ceil((new Date(isoDate).getTime() - Date.now()) / 86_400_000);
}

function dueClass(days: number): string {
  if (days < 0) return styles.dueOverdue;
  if (days <= 30) return styles.dueWarn;
  return styles.due;
}

export function UpcomingPage() {
  const { data: loggers = [], isLoading } = useQuery<LoggerSummary[]>({
    queryKey: ["loggers-all"],
    queryFn: () => apiFetch("/api/loggers?limit=200"),
  });

  const due = loggers
    .filter((lg) => lg.next_due_at != null)
    .map((lg) => ({ ...lg, days: daysUntil(lg.next_due_at!) }))
    .filter((lg) => lg.days <= 90)
    .sort((a, b) => a.days - b.days);

  const overdue = due.filter((lg) => lg.days < 0);
  const next30 = due.filter((lg) => lg.days >= 0 && lg.days <= 30);
  const next60 = due.filter((lg) => lg.days > 30 && lg.days <= 60);
  const next90 = due.filter((lg) => lg.days > 60 && lg.days <= 90);

  const cols = [
    { key: "serial_no" as const, header: "Serial No." },
    { key: "model" as const, header: "Model", render: (lg: LoggerSummary & { days: number }) => lg.model ?? "—" },
    {
      key: "days" as const,
      header: "Due",
      render: (lg: LoggerSummary & { days: number }) => (
        <span className={dueClass(lg.days)}>
          {lg.days < 0 ? `${-lg.days}d overdue` : lg.days === 0 ? "Today" : `In ${lg.days}d`}
        </span>
      ),
    },
    {
      key: "next_due_at" as const,
      header: "Date",
      render: (lg: LoggerSummary & { days: number }) =>
        new Date(lg.next_due_at!).toLocaleDateString(),
    },
  ];

  const Section = ({ title, rows }: { title: string; rows: (LoggerSummary & { days: number })[] }) =>
    rows.length === 0 ? null : (
      <div style={{ marginBottom: "var(--s-5)" }}>
        <p className={styles.historyTitle}>{title} ({rows.length})</p>
        <DataTable columns={cols} rows={rows} getKey={(lg) => lg.id} emptyMessage="" />
      </div>
    );

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h1 className={styles.title}>Upcoming calibrations</h1>
      </div>

      {isLoading && <p className={styles.empty}>Loading…</p>}
      {!isLoading && due.length === 0 && (
        <p className={styles.empty}>No loggers due within 90 days.</p>
      )}

      <Section title="Overdue" rows={overdue} />
      <Section title="Due within 30 days" rows={next30} />
      <Section title="Due 31–60 days" rows={next60} />
      <Section title="Due 61–90 days" rows={next90} />
    </div>
  );
}
