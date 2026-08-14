import styles from "./StatTile.module.css";

interface Props {
  label: string;
  value: number | string | null;
  unit?: string;
  accent?: "default" | "warn" | "fail" | "pass";
}

export function StatTile({ label, value, unit, accent = "default" }: Props) {
  return (
    <div className={`${styles.tile} ${styles[accent]}`}>
      <span className={styles.label}>{label}</span>
      <span className={styles.value}>
        {value === null ? "—" : value}
        {unit && value !== null && <span className={styles.unit}>{unit}</span>}
      </span>
    </div>
  );
}
