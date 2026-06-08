import { useState } from "react";
import { Link } from "react-router-dom";
import { ApiError, apiFetch } from "../api/client";
import styles from "./LoginPage.module.css";

export function RegisterPage() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [role, setRole] = useState("engineer");
  const [err, setErr] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    if (!fullName.trim()) { setErr("Full name is required."); return; }
    if (password.length < 8) { setErr("Password must be at least 8 characters."); return; }
    if (password !== confirm) { setErr("Passwords do not match."); return; }

    setSubmitting(true);
    try {
      await apiFetch("/api/auth/register", {
        method: "POST",
        json: { email, full_name: fullName.trim(), password, role },
      });
      setDone(true);
    } catch (e) {
      if (e instanceof ApiError && e.status === 422) {
        setErr("Password must be at least 8 characters.");
      } else {
        setErr("Something went wrong. Please try again.");
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (done) {
    return (
      <main className={styles.wrap}>
        <div className={styles.card}>
          <h1 className={styles.title}>You're on the list</h1>
          <p className={styles.subtitle}>
            Your account is pending admin approval. Once approved you can sign in
            straight away — no extra steps needed.
          </p>
          <Link to="/login" className={styles.forgotLink}
            style={{ textAlign: "center", display: "block", marginTop: "24px" }}>
            Back to sign in
          </Link>
        </div>
      </main>
    );
  }

  return (
    <main className={styles.wrap}>
      <form className={styles.card} onSubmit={onSubmit} noValidate>
        <h1 className={styles.title}>Create account</h1>
        <p className={styles.subtitle}>
          Request access — an admin will approve your account.
        </p>

        <label className={styles.field}>
          <span className={styles.label}>Full name <span className={styles.required}>*</span></span>
          <input className={styles.input} type="text" autoComplete="name" required
            value={fullName} onChange={(e) => setFullName(e.target.value)} />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Email <span className={styles.required}>*</span></span>
          <input className={styles.input} type="email" autoComplete="email" required
            value={email} onChange={(e) => setEmail(e.target.value)} />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Password <span className={styles.required}>*</span></span>
          <input className={styles.input} type="password" autoComplete="new-password" required
            value={password} onChange={(e) => setPassword(e.target.value)} />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Confirm password <span className={styles.required}>*</span></span>
          <input className={styles.input} type="password" autoComplete="new-password" required
            value={confirm} onChange={(e) => setConfirm(e.target.value)} />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Role</span>
          <select className={styles.input} value={role}
            onChange={(e) => setRole(e.target.value)} style={{ cursor: "pointer" }}>
            <option value="viewer">Viewer — read-only</option>
            <option value="engineer">Engineer — run calibrations</option>
          </select>
        </label>

        {err && <div className={styles.error} role="alert">{err}</div>}

        <div className={styles.btnWrap}>
          <button className={`${styles.button} ${submitting ? styles.buttonLoading : ""}`}
            disabled={submitting} type="submit">
            Create account
          </button>
          {submitting && (
            <div className={styles.spinnerOverlay}>
              <span className={styles.spinner} />Submitting…
            </div>
          )}
        </div>

        <Link to="/login" className={styles.forgotLink}
          style={{ textAlign: "center", marginTop: "16px" }}>
          Already have an account? Sign in
        </Link>
      </form>
    </main>
  );
}
