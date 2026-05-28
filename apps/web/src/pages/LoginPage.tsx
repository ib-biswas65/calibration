import { Eye, EyeOff } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { Link, useLocation, useNavigate } from "react-router-dom";
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
  const [leaving, setLeaving] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

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
      setLeaving(true);
      setTimeout(() => nav(next, { replace: true }), 330);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setSubmitErr("Invalid email or password.");
      else if (e instanceof ApiError && e.status === 429) setSubmitErr("Too many attempts. Try again later.");
      else setSubmitErr("Something went wrong.");
    }
  };

  return (
    <main className={styles.wrap}>
      <form
        className={`${styles.card} ${leaving ? styles.cardLeaving : ""}`}
        onSubmit={handleSubmit(onSubmit)}
        noValidate
      >
        <h1 className={`${styles.title} ${leaving ? styles.titleLeaving : ""}`}>
          ITE Calibration
        </h1>
        <p className={styles.subtitle}>Sign in to continue</p>

        <label className={styles.field}>
          <span className={styles.label}>Email <span className={styles.required} aria-hidden="true">*</span></span>
          <input
            className={styles.input}
            type="email"
            autoComplete="email"
            aria-label="Email"
            {...register("email")}
          />
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Password <span className={styles.required} aria-hidden="true">*</span></span>
          <div className={styles.passWrap}>
            <input
              className={styles.input}
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              aria-label="Password"
              {...register("password")}
            />
            <button
              type="button"
              className={styles.passToggle}
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? "Hide password" : "Show password"}
            >
              {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </div>
        </label>

        <Link to="/reset-password" className={styles.forgotLink}>
          Forgot password?
        </Link>

        {submitErr && (
          <div key={submitErr} className={styles.error} role="alert">
            {submitErr}
          </div>
        )}

        <div className={styles.btnWrap}>
          <button
            className={`${styles.button} ${isSubmitting ? styles.buttonLoading : ""}`}
            disabled={isSubmitting}
            type="submit"
          >
            Sign in
          </button>
          {isSubmitting && (
            <div className={styles.spinnerOverlay}>
              <span className={styles.spinner} />
              Signing in…
            </div>
          )}
        </div>
      </form>
    </main>
  );
}
