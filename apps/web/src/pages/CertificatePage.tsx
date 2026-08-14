import { useState } from "react";
import { Link } from "react-router-dom";

import { ApiError, apiFetch } from "../api/client";
import { StatusPill } from "../components/StatusPill";
import styles from "./CertificatePage.module.css";

interface CertResult {
  result_id: string;
  run_id: string;
  cert_no: string;
  sheet_name: string;
  verdict: string;
  batch_name: string | null;
  certificate_date: string | null;
}

export function CertificatePage() {
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<CertResult | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [searching, setSearching] = useState(false);

  const search = async (e: React.FormEvent) => {
    e.preventDefault();
    const q = query.trim();
    if (!q) return;
    setErr(null);
    setResult(null);
    setSearching(true);
    try {
      const data = await apiFetch<CertResult>(`/api/runs/by-cert-no/${encodeURIComponent(q)}`);
      setResult(data);
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) setErr(`No certificate found for number "${q}".`);
      else setErr("Something went wrong. Please try again.");
    } finally {
      setSearching(false);
    }
  };

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>Certificate lookup</h1>
      <p className={styles.subtitle}>Enter a certificate number to find the associated calibration run.</p>

      <form className={styles.form} onSubmit={search}>
        <input
          className={styles.input}
          placeholder="e.g. 0000001800"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          spellCheck={false}
        />
        <button className={styles.btn} disabled={searching || !query.trim()} type="submit">
          {searching ? "Searching…" : "Look up"}
        </button>
      </form>

      {err && <p className={styles.err} role="alert">{err}</p>}

      {result && (
        <div className={styles.card}>
          <div className={styles.cardRow}>
            <span className={styles.cardLabel}>Cert no.</span>
            <strong>{result.cert_no}</strong>
          </div>
          <div className={styles.cardRow}>
            <span className={styles.cardLabel}>Logger</span>
            <span>{result.sheet_name}</span>
          </div>
          <div className={styles.cardRow}>
            <span className={styles.cardLabel}>Verdict</span>
            <StatusPill value={result.verdict} />
          </div>
          {result.batch_name && (
            <div className={styles.cardRow}>
              <span className={styles.cardLabel}>Batch</span>
              <span>{result.batch_name}</span>
            </div>
          )}
          {result.certificate_date && (
            <div className={styles.cardRow}>
              <span className={styles.cardLabel}>Date</span>
              <span>{new Date(result.certificate_date).toLocaleDateString()}</span>
            </div>
          )}
          <div className={styles.actions}>
            <a
              className={styles.downloadBtn}
              href={`/api/runs/${result.run_id}/results/${result.result_id}/certificate`}
              download
            >
              Download .docx
            </a>
            <Link className={styles.viewBtn} to={`/calibrations/${result.run_id}`}>
              View run
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
