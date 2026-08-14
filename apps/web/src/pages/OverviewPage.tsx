import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
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

function SkeletonTile() {
  return (
    <div className={styles.skeletonTile}>
      <div className={styles.skeleton} style={{ width: "40%", height: 32, marginBottom: 6 }} />
      <div className={styles.skeleton} style={{ width: "60%", height: 12 }} />
    </div>
  );
}

function SkeletonRail() {
  return (
    <div className={styles.rail}>
      <div className={`${styles.skeleton} ${styles.skeletonTitle}`} />
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className={styles.skeletonItem}>
          <div className={styles.skeleton} style={{ width: "55%" }} />
          <div className={styles.skeleton} style={{ width: "20%" }} />
        </div>
      ))}
    </div>
  );
}

export function OverviewPage() {
  const { data, isLoading, error } = useOverview();
  const nav = useNavigate();

  if (isLoading) {
    return (
      <div className={styles.page}>
        <h2 className={styles.heading}>Overview</h2>
        <div className={styles.tiles}>
          <SkeletonTile /><SkeletonTile /><SkeletonTile /><SkeletonTile />
        </div>
        <div className={styles.rails}>
          <SkeletonRail /><SkeletonRail />
        </div>
      </div>
    );
  }

  if (error || !data) return <div className={styles.loading}>Failed to load overview.</div>;

  const { fleet, last_30d, recent_runs, due_soon } = data;

  const chartData = [...recent_runs]
    .reverse()
    .slice(0, 10)
    .map((r) => ({
      name: r.batch_name.length > 12 ? r.batch_name.slice(0, 10) + "…" : r.batch_name,
      pass: r.verdict_mix?.pass ?? 0,
      fail: r.verdict_mix?.fail ?? 0,
    }))
    .filter((d) => d.pass + d.fail > 0);

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
            <div className={styles.emptyState}>
              <span className={styles.emptyLabel}>No runs yet</span>
              <span className={styles.emptySub}>Start a new calibration to see results here</span>
            </div>
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
            <div className={styles.emptyState}>
              <span className={styles.emptyLabel}>All up to date</span>
              <span className={styles.emptySub}>No loggers due for calibration within 30 days</span>
            </div>
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

      {chartData.length > 0 && (
        <section className={styles.chartSection}>
          <h3 className={styles.railTitle}>Pass / fail trend (last {chartData.length} runs)</h3>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={chartData} margin={{ top: 4, right: 16, left: -20, bottom: 4 }} barSize={18}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--c-border)" vertical={false} />
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: "var(--c-text-mute)" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "var(--c-text-mute)" }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip
                contentStyle={{ background: "var(--c-surface)", border: "1px solid var(--c-border)", borderRadius: 8, fontSize: 12 }}
                cursor={{ fill: "var(--c-accent-50)" }}
              />
              <Bar dataKey="pass" name="Pass" fill="var(--c-pass)" radius={[3, 3, 0, 0]} />
              <Bar dataKey="fail" name="Fail" fill="var(--c-fail)" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </section>
      )}
    </div>
  );
}
