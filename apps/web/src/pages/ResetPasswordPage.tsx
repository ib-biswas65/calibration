import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { apiFetch } from "../api/client";
import styles from "./LoginPage.module.css";

export function ResetPasswordPage() {
  const [params] = useSearchParams();
  const nav = useNavigate();
  const token = params.get("token") ?? "";

  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (!token) {
    return (
      <main className={styles.wrap}>
        <div className={styles.card}>
          <h1 className={styles.title}>Invalid link</h1>
          <p className={styles.subtitle}>This password reset link is missing a token.</p>
        </div>
      </main>
    );
  }

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    if (password.length < 12) {
      setErr("Password must be at least 12 characters.");
      return;
    }
    if (password !== confirm) {
      setErr("Passwords do not match.");
      return;
    }
    setSubmitting(true);
    try {
      await apiFetch("/api/auth/reset-password", {
        method: "POST",
        json: { token, password },
      });
      nav("/", { replace: true });
    } catch {
      setErr("This link is invalid or has already been used.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className={styles.wrap}>
      <form className={styles.card} onSubmit={onSubmit} noValidate>
        <h1 className={styles.title}>Set your password</h1>
        <p className={styles.subtitle}>Choose a password to complete your account setup.</p>

        <label className={styles.field}>
          <span className={styles.label}>New password</span>
          <input
            className={styles.input}
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Confirm password</span>
          <input
            className={styles.input}
            type="password"
            autoComplete="new-password"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
          />
        </label>

        {err && <div className={styles.error} role="alert">{err}</div>}

        <button className={styles.button} disabled={submitting} type="submit">
          {submitting ? "Saving…" : "Set password and sign in"}
        </button>
      </form>
    </main>
  );
}
