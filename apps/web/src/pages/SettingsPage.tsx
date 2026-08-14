import { Eye, EyeOff, LogOut } from "lucide-react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { ApiError, apiFetch } from "../api/client";
import { useAuth } from "../auth/useAuth";
import { useToast } from "../components/Toast";
import loginStyles from "./LoginPage.module.css";
import styles from "./SettingsPage.module.css";

export function SettingsPage() {
  const { user, logout } = useAuth();
  const { toast } = useToast();
  const nav = useNavigate();

  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [showCurrent, setShowCurrent] = useState(false);
  const [showNext, setShowNext] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const [loggingOutAll, setLoggingOutAll] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    if (next.length < 12) { setErr("New password must be at least 12 characters."); return; }
    if (next !== confirm) { setErr("Passwords do not match."); return; }
    setSubmitting(true);
    try {
      await apiFetch("/api/auth/change-password", {
        method: "POST",
        json: { current_password: current, new_password: next },
      });
      toast("Password changed successfully.", "success");
      setCurrent(""); setNext(""); setConfirm("");
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setErr("Current password is incorrect.");
      else setErr("Something went wrong.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleLogoutAll = async () => {
    setLoggingOutAll(true);
    try {
      await apiFetch("/api/auth/logout?all_sessions=true", { method: "POST" });
      await logout();
      nav("/login", { replace: true });
    } catch {
      toast("Failed to log out all sessions.", "error");
      setLoggingOutAll(false);
    }
  };

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>Settings</h1>

      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Account</h2>
        <div className={styles.info}>
          <span className={styles.infoLabel}>Email</span>
          <span>{user?.email}</span>
        </div>
        <div className={styles.info}>
          <span className={styles.infoLabel}>Name</span>
          <span>{user?.full_name}</span>
        </div>
        <div className={styles.info}>
          <span className={styles.infoLabel}>Role</span>
          <span style={{ textTransform: "capitalize" }}>{user?.role}</span>
        </div>
      </div>

      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Change password</h2>
        <form className={styles.form} onSubmit={onSubmit} noValidate>
          <label className={loginStyles.field}>
            <span className={loginStyles.label}>Current password</span>
            <div className={loginStyles.passWrap}>
              <input className={loginStyles.input} type={showCurrent ? "text" : "password"}
                autoComplete="current-password" value={current} onChange={(e) => setCurrent(e.target.value)} />
              <button type="button" className={loginStyles.passToggle}
                onClick={() => setShowCurrent((v) => !v)}
                aria-label={showCurrent ? "Hide password" : "Show password"}>
                {showCurrent ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </label>
          <label className={loginStyles.field}>
            <span className={loginStyles.label}>New password <span className={styles.hint}>(min. 12 characters)</span></span>
            <div className={loginStyles.passWrap}>
              <input className={loginStyles.input} type={showNext ? "text" : "password"}
                autoComplete="new-password" value={next} onChange={(e) => setNext(e.target.value)} />
              <button type="button" className={loginStyles.passToggle}
                onClick={() => setShowNext((v) => !v)}
                aria-label={showNext ? "Hide password" : "Show password"}>
                {showNext ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </label>
          <label className={loginStyles.field}>
            <span className={loginStyles.label}>Confirm new password</span>
            <div className={loginStyles.passWrap}>
              <input className={loginStyles.input} type={showConfirm ? "text" : "password"}
                autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
              <button type="button" className={loginStyles.passToggle}
                onClick={() => setShowConfirm((v) => !v)}
                aria-label={showConfirm ? "Hide password" : "Show password"}>
                {showConfirm ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </label>
          {err && <div className={loginStyles.error} role="alert">{err}</div>}
          <button className={styles.btn} disabled={submitting} type="submit">
            {submitting ? "Saving…" : "Change password"}
          </button>
        </form>
      </div>

      <div className={`${styles.section} ${styles.dangerSection}`}>
        <h2 className={styles.sectionTitle}>Sessions</h2>
        <p className={styles.dangerNote}>Log out of all devices and browser sessions, including this one.</p>
        <button className={styles.btnDanger} disabled={loggingOutAll} onClick={handleLogoutAll}>
          <LogOut size={14} aria-hidden="true" />
          {loggingOutAll ? "Logging out…" : "Log out all sessions"}
        </button>
      </div>
    </div>
  );
}
