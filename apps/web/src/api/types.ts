export type Role = "admin" | "engineer" | "viewer";

export interface AuthMe {
  id: string;
  email: string;
  full_name: string;
  role: Role;
}

export type RunStatus = "draft" | "processing" | "complete" | "failed";
export type Verdict = "pass" | "fail" | "adjusted";

export interface SetpointConfig {
  target_c: number;
  start_at: string;
  end_at: string;
}

export interface PerSetpoint {
  target_c: number;
  ref_c: number | null;
  cal_c: number | null;
  dev_c: number | null;
  within_tol: boolean;
}

export interface LoggerResult {
  id: string;
  sheet_name: string;
  verdict: Verdict;
  max_deviation_c: number | null;
  cert_no: string | null;
  per_setpoint: PerSetpoint[];
}

export interface ReferenceFile {
  id: string;
  original_name: string;
  sha256: string;
}

export interface CalibrationFile {
  id: string;
  original_name: string;
  sha256: string;
  sheet_names: string[];
}

export interface RunSummary {
  id: string;
  batch_name: string;
  status: RunStatus;
  created_at: string;
  completed_at: string | null;
  logger_count: number | null;
  pass_rate: number | null;
  max_deviation_c: number | null;
}

export interface RunDetail {
  id: string;
  batch_name: string;
  status: RunStatus;
  testing_start: string;
  testing_end: string;
  certificate_date: string;
  threshold_c: number;
  setpoints: SetpointConfig[];
  start_cert_no: string;
  cert_width: number;
  test_date_jp: string;
  doc_date_jp: string;
  failure_reason: { message?: string } | null;
  created_at: string;
  completed_at: string | null;
  reference_files: ReferenceFile[];
  calibration_file: CalibrationFile | null;
  results: LoggerResult[];
}

export interface OverviewFleet {
  total_loggers: number;
  due_30d: number;
  overdue: number;
}

export interface OverviewLast30d {
  runs: number;
  pass_rate: number | null;
  fail_count: number;
  adjusted_count: number;
}

export interface OverviewRecentRun {
  id: string;
  batch_name: string;
  status: RunStatus;
  created_at: string;
  verdict_mix: Record<string, number>;
}

export interface OverviewDueSoon {
  logger_id: string;
  serial_no: string;
  next_due_at: string | null;
}

export interface OverviewResponse {
  fleet: OverviewFleet;
  last_30d: OverviewLast30d;
  recent_runs: OverviewRecentRun[];
  due_soon: OverviewDueSoon[];
}

export interface UserOut {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  disabled: boolean;
  created_at: string;
  last_login_at: string | null;
}

export interface LoggerSummary {
  id: string;
  serial_no: string;
  model: string | null;
  notes: string | null;
  next_due_at: string | null;
}

export interface FileUploadResponse {
  file_id: string;
  sha256: string;
  original_name: string;
}

export interface CalibrationUploadResponse extends FileUploadResponse {
  sheet_names: string[];
}
