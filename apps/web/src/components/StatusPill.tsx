import styles from "./StatusPill.module.css";
import type { RunStatus, Verdict } from "../api/types";

const LABELS: Record<string, string> = {
  draft: "Draft",
  processing: "Processing",
  complete: "Complete",
  failed: "Failed",
  pass: "Pass",
  fail: "Fail",
  adjusted: "Adjusted",
};

interface Props {
  value: RunStatus | Verdict | string;
}

export function StatusPill({ value }: Props) {
  return (
    <span className={`${styles.pill} ${styles[value] ?? ""}`}>
      {LABELS[value] ?? value}
    </span>
  );
}
