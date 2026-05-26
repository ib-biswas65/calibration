import { useState } from "react";
import { useForm } from "react-hook-form";
import { useLocation, useNavigate } from "react-router-dom";
import { z } from "zod";

import { ApiError } from "../api/client";
import { useAuth } from "../auth/useAuth";
import styles from "./LoginPage.module.css";

const Schema = z.object({
  email: z.string().email("Enter a valid email"),
  password: z.string().min(1, "Required"),
});
type FormValues = z.infer<typeof Schema>;

interface LocationState { from?: string }

export function LoginPage() {
  const { login } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();
  const [submitErr, setSubmitErr] = useState<string | null>(null);

  const { register, handleSubmit, formState: { isSubmitting } } = useForm<FormValues>();

  const onSubmit = async (raw: FormValues) => {
    setSubmitErr(null);
    const parsed = Schema.safeParse(raw);
    if (!parsed.success) {
      setSubmitErr(parsed.error.issues[0]?.message ?? "Invalid input");
      return;
    }
    try {
      await login(parsed.data.email, parsed.data.password);
      const next = (loc.state as LocationState | null)?.from ?? "/";
      nav(next, { replace: true });
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setSubmitErr("Invalid email or password.");
      else if (e instanceof ApiError && e.status === 429) setSubmitErr("Too many attempts. Try again later.");
      else setSubmitErr("Something went wrong.");
    }
  };

  return (
    <main className={styles.wrap}>
      <form className={styles.card} onSubmit={handleSubmit(onSubmit)} noValidate>
        <h1 className={styles.title}>ITE Calibration</h1>
        <p className={styles.subtitle}>Sign in to continue</p>

        <label className={styles.field}>
          <span className={styles.label}>Email</span>
          <input
            className={styles.input}
            type="email"
            autoComplete="email"
            aria-label="Email"
            {...register("email")}
          />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Password</span>
          <input
            className={styles.input}
            type="password"
            autoComplete="current-password"
            aria-label="Password"
            {...register("password")}
          />
        </label>

        {submitErr && <div className={styles.error} role="alert">{submitErr}</div>}

        <button className={styles.button} disabled={isSubmitting} type="submit">
          Sign in
        </button>
      </form>
    </main>
  );
}
