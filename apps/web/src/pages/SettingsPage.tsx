import { useState } from "react";

import { ApiError, apiFetch } from "../api/client";
import { useAuth } from "../auth/useAuth";
import { useToast } from "../components/Toast";
import styles from "./LoginPage.module.css";
import pageStyles from "./SettingsPage.module.css";

export function SettingsPage() {
  const { user } = useAuth();
  const { toast } = useToast();

  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

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

  return (
    <div className={pageStyles.page}>
      <h1 className={pageStyles.title}>Settings</h1>

      <div className={pageStyles.section}>
        <h2 className={pageStyles.sectionTitle}>Account</h2>
        <div className={pageStyles.info}>
          <span className={pageStyles.infoLabel}>Email</span>
          <span>{user?.email}</span>
        </div>
        <div className={pageStyles.info}>
          <span className={pageStyles.infoLabel}>Name</span>
          <span>{user?.full_name}</span>
        </div>
        <div className={pageStyles.info}>
          <span className={pageStyles.infoLabel}>Role</span>
          <span style={{ textTransform: "capitalize" }}>{user?.role}</span>
        </div>
      </div>

      <div className={pageStyles.section}>
        <h2 className={pageStyles.sectionTitle}>Change password</h2>
        <form className={pageStyles.form} onSubmit={onSubmit} noValidate>
          <label className={styles.field}>
            <span className={styles.label}>Current password</span>
            <input className={styles.input} type="password" autoComplete="current-password"
              value={current} onChange={(e) => setCurrent(e.target.value)} />
          </label>
          <label className={styles.field}>
            <span className={styles.label}>New password</span>
            <input className={styles.input} type="password" autoComplete="new-password"
              value={next} onChange={(e) => setNext(e.target.value)} />
          </label>
          <label className={styles.field}>
            <span className={styles.label}>Confirm new password</span>
            <input className={styles.input} type="password" autoComplete="new-password"
              value={confirm} onChange={(e) => setConfirm(e.target.value)} />
          </label>
          {err && <div className={styles.error} role="alert">{err}</div>}
          <button className={pageStyles.btn} disabled={submitting} type="submit">
            {submitting ? "Saving…" : "Change password"}
          </button>
        </form>
      </div>
    </div>
  );
}
