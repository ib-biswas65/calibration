# Change Log

Notable production changes and re-issued certificates. Newest entries first.

## 2026-08-27 — Reference-instrument label/value update in certificate template

**What changed**

- Renamed the reference-instrument field in the certificate template from
  "製造番号" (Serial No.) to "機器番号・証明書番号" (Device No. / Certificate
  No.), and updated its value from `B250884` to `MC255B012-B260691`.
  (`apps/api/ite_api/calibration/template.docx`, mirrored in
  `apps/api/tests/fixtures/calibration/template.docx`)
- Follow-up fix: the new value is longer than the old one, which pushed the
  manufacturer name ("株式会社チノー") past the line width in the reference
  row, wrapping "ー" onto its own line. Trimmed the row's padding so it fits
  on one line again.

**Commits** (`main`)

- `d36086e` — Update reference-instrument label and value in certificate template
- `5782bc0` — Fix reference-instrument row wrapping in certificate template

**Deployed**

- `api` image rebuilt from `main` and redeployed on the production Docker
  stack (`deploy-package/`) twice — once per commit above.
- Prior images kept as rollback tags: `ite-calibration-api:backup-20260827`,
  `ite-calibration-api:backup-20260827-b`.

**Certificates re-issued**

- Run **"14th August 2026 74 loggers"** (`6346314f-d148-49d3-88b4-74696f76b1a6`,
  completed 2026-08-14) — all 74 certificates regenerated in place from the
  original uploaded reference/calibration data, using the updated template.
  Dates, cert numbers, logger serials, and calibration results are unchanged
  from the original run — only the template layout differs.
- Pre-update certificates backed up on the data volume at
  `runs/6346314f-d148-49d3-88b4-74696f76b1a6/certificates_backup_20260827`
  and `..._backup_20260827b` (before and after the wrapping fix, respectively).
