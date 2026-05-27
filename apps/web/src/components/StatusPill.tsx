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
  const cls = [styles.pill, styles[value] ?? "", value === "processing" ? styles.pulsing : ""]
    .filter(Boolean)
    .join(" ");
  return <span className={cls}>{LABELS[value] ?? value}</span>;
}
