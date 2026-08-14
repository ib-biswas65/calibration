import styles from "./SetpointWindowRow.module.css";

export interface SetpointValue {
  target_c: number;
  start_at: string;
  end_at: string;
}

interface Props {
  value: SetpointValue;
  onChange: (v: SetpointValue) => void;
}

function durationLabel(start: string, end: string): string {
  if (!start || !end) return "";
  const ms = new Date(end).getTime() - new Date(start).getTime();
  if (isNaN(ms) || ms < 0) return "";
  const h = Math.floor(ms / 3_600_000);
  const m = Math.floor((ms % 3_600_000) / 60_000);
  if (h === 0) return `${m}m`;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

export function SetpointWindowRow({ value, onChange }: Props) {
  const dur = durationLabel(value.start_at, value.end_at);

  return (
    <div className={styles.row}>
      <span className={styles.target}>{value.target_c > 0 ? "+" : ""}{value.target_c}°C</span>
      <div className={styles.inputs}>
        <label className={styles.field}>
          <span>Start</span>
          <input
            type="datetime-local"
            value={value.start_at.slice(0, 16)}
            onChange={(e) => onChange({ ...value, start_at: e.target.value + ":00Z" })}
          />
        </label>
        <span className={styles.arrow}>→</span>
        <label className={styles.field}>
          <span>End</span>
          <input
            type="datetime-local"
            value={value.end_at.slice(0, 16)}
            onChange={(e) => onChange({ ...value, end_at: e.target.value + ":00Z" })}
          />
        </label>
        {dur && <span className={styles.duration}>{dur}</span>}
      </div>
    </div>
  );
}
