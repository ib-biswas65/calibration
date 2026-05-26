import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { OverviewResponse } from "../api/types";
import { StatTile } from "../components/StatTile";
import { StatusPill } from "../components/StatusPill";
import styles from "./OverviewPage.module.css";

function useOverview() {
  return useQuery<OverviewResponse>({
    queryKey: ["overview"],
    queryFn: () => apiFetch<OverviewResponse>("/api/overview"),
    refetchInterval: 30_000,
  });
}

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

export function OverviewPage() {
  const { data, isLoading, error } = useOverview();
  const nav = useNavigate();

  if (isLoading) return <div className={styles.loading}>Loading…</div>;
  if (error || !data) return <div className={styles.loading}>Failed to load overview.</div>;

  const { fleet, last_30d, recent_runs, due_soon } = data;

  return (
    <div className={styles.page}>
      <h2 className={styles.heading}>Overview</h2>

      <div className={styles.tiles}>
        <StatTile label="Total loggers" value={fleet.total_loggers} />
        <StatTile label="Runs (30 d)" value={last_30d.runs} />
        <StatTile
          label="Pass rate"
          value={last_30d.pass_rate !== null ? last_30d.pass_rate.toFixed(1) : null}
          unit="%"
          accent={last_30d.pass_rate !== null && last_30d.pass_rate < 90 ? "warn" : "pass"}
        />
        <StatTile
          label="Overdue"
          value={fleet.overdue}
          accent={fleet.overdue > 0 ? "fail" : "default"}
        />
      </div>

      <div className={styles.rails}>
        <section className={styles.rail}>
          <h3 className={styles.railTitle}>Recent runs</h3>
          {recent_runs.length === 0 ? (
            <p className={styles.empty}>No runs yet.</p>
          ) : (
            <ul className={styles.list}>
              {recent_runs.map((run) => (
                <li key={run.id} className={styles.item} onClick={() => nav(`/calibrations/${run.id}`)}>
                  <div className={styles.itemMain}>
                    <span className={styles.batchName}>{run.batch_name}</span>
                    <StatusPill value={run.status} />
                  </div>
                  <span className={styles.itemSub}>{fmt(run.created_at)}</span>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className={styles.rail}>
          <h3 className={styles.railTitle}>Due soon</h3>
          {due_soon.length === 0 ? (
            <p className={styles.empty}>No loggers due in 30 days.</p>
          ) : (
            <ul className={styles.list}>
              {due_soon.map((lg) => (
                <li key={lg.logger_id} className={styles.item}>
                  <span className={styles.batchName}>{lg.serial_no}</span>
                  <span className={styles.itemSub}>{lg.next_due_at ?? "—"}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </div>
  );
}
