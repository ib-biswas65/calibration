import { useQuery } from "@tanstack/react-query";
import { Download } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { RunSummary } from "../api/types";
import { SortIcon, type SortDir } from "../components/SortIcon";
import { StatusPill } from "../components/StatusPill";
import styles from "./HistoryPage.module.css";

type SortKey = "batch_name" | "created_at" | "pass_rate" | "max_deviation_c";

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

function SkeletonRow() {
  return (
    <tr>
      {[70, 60, 40, 120, 50, 80].map((w, i) => (
        <td key={i}><div className={styles.skeleton} style={{ width: `${w}%`, maxWidth: w }} /></td>
      ))}
    </tr>
  );
}

export function HistoryPage() {
  const nav = useNavigate();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("created_at");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

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

  const sortedFiltered = useMemo(() => {
    let rows = [...data];

    if (dateFrom) {
      const from = new Date(dateFrom).getTime();
      rows = rows.filter((r) => new Date(r.created_at).getTime() >= from);
    }
    if (dateTo) {
      const to = new Date(dateTo).getTime() + 86_400_000;
      rows = rows.filter((r) => new Date(r.created_at).getTime() <= to);
    }

    rows.sort((a, b) => {
      let av: string | number | null, bv: string | number | null;
      if (sortKey === "batch_name") { av = a.batch_name; bv = b.batch_name; }
      else if (sortKey === "created_at") { av = a.created_at; bv = b.created_at; }
      else if (sortKey === "pass_rate") { av = a.pass_rate ?? -1; bv = b.pass_rate ?? -1; }
      else { av = a.max_deviation_c ?? -1; bv = b.max_deviation_c ?? -1; }

      if (av === bv) return 0;
      const cmp = av < bv ? -1 : 1;
      return sortDir === "asc" ? cmp : -cmp;
    });

    return rows;
  }, [data, dateFrom, dateTo, sortKey, sortDir]);

  function handleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir((d) => d === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  }

  function handleExportCsv() {
    const headers = ["Batch name", "Status", "Loggers", "Pass rate (%)", "Max deviation (°C)", "Date"];
    const rows = sortedFiltered.map((r) => [
      `"${r.batch_name.replace(/"/g, '""')}"`,
      r.status,
      r.logger_count ?? "",
      r.pass_rate !== null ? r.pass_rate.toFixed(1) : "",
      r.max_deviation_c !== null ? r.max_deviation_c.toFixed(2) : "",
      fmt(r.created_at),
    ]);
    const csv = [headers, ...rows].map((r) => r.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `calibration-history-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const thProps = (key: SortKey) => ({
    className: `${styles.thSort} ${sortKey === key ? styles.thSortActive : ""}`,
    onClick: () => handleSort(key),
    "aria-sort": sortKey === key ? (sortDir === "asc" ? "ascending" : "descending") : "none" as React.AriaAttributes["aria-sort"],
  });

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h2 className={styles.heading}>Calibration History</h2>
        <div className={styles.headerActions}>
          <button className={styles.exportBtn} onClick={handleExportCsv} disabled={data.length === 0}>
            <Download size={13} aria-hidden="true" /> Export CSV
          </button>
          <button className={styles.btnPrimary} onClick={() => nav("/new")}>+ New calibration</button>
        </div>
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
        <label className={styles.dateLabel}>
          From
          <input type="date" className={styles.dateInput} value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        </label>
        <label className={styles.dateLabel}>
          To
          <input type="date" className={styles.dateInput} value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        </label>
      </div>

      <div className={styles.tableWrap}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th {...thProps("batch_name")}>
                Batch name <SortIcon active={sortKey === "batch_name"} dir={sortDir} className={styles.sortIconInactive} />
              </th>
              <th>Status</th>
              <th className={styles.colNum}>Loggers</th>
              <th {...thProps("pass_rate")} className={`${styles.thSort} ${sortKey === "pass_rate" ? styles.thSortActive : ""} ${styles.colWide}`}>
                Pass rate <SortIcon active={sortKey === "pass_rate"} dir={sortDir} className={styles.sortIconInactive} />
              </th>
              <th {...thProps("max_deviation_c")} className={`${styles.thSort} ${sortKey === "max_deviation_c" ? styles.thSortActive : ""} ${styles.colNum}`}>
                Max dev. <SortIcon active={sortKey === "max_deviation_c"} dir={sortDir} className={styles.sortIconInactive} />
              </th>
              <th {...thProps("created_at")} className={`${styles.thSort} ${sortKey === "created_at" ? styles.thSortActive : ""} ${styles.colNum}`}>
                Date <SortIcon active={sortKey === "created_at"} dir={sortDir} className={styles.sortIconInactive} />
              </th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              Array.from({ length: 6 }).map((_, i) => <SkeletonRow key={i} />)
            ) : sortedFiltered.length === 0 ? (
              <tr>
                <td colSpan={6} className={styles.empty}>No calibration runs found</td>
              </tr>
            ) : (
              sortedFiltered.map((run) => (
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
    </div>
  );
}
