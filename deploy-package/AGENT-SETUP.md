# ITE Calibration — Agent Setup Runbook

> **For the AI agent running this:** Execute every step in order. Verify the
> expected output before proceeding to the next step. If any step produces an
> error, stop and report it with the full output before continuing.

---

## What you are setting up

A self-contained web application (FastAPI + React + PostgreSQL) that runs
entirely inside Docker. After setup, users open `http://localhost` in a browser.
All calibration history is pre-loaded — no data entry required.

---

## Prerequisites — verify before starting

### 1. Docker Desktop is installed and running

```powershell
docker version
```

**Expected:** Two blocks of version info — `Client:` and `Server:`.
If you get `error during connect` or a command-not-found error, Docker Desktop
is not running. Start it from the Start Menu and wait until the whale icon in
the taskbar shows "Engine running", then retry.

### 2. This folder contains the required files

```powershell
Get-ChildItem -Name
```

**Expected — all of these must be present:**
```
.env.example
backup-windows.ps1
cal_data.tar.gz
docker-compose.yml
images\
nginx.conf
seed\
setup-windows.ps1
```

If `images\api.tar.gz`, `images\web.tar.gz`, `seed\db_full.sql`, or
`cal_data.tar.gz` are missing, the deploy package is incomplete. Stop here.

---

## Step 1 — Create and populate `.env`

### 1a. Create the file

```powershell
Copy-Item .env.example .env
```

### 1b. Generate a strong JWT secret

```powershell
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$secret = [System.Convert]::ToHexString($bytes).ToLower()
Write-Host "JWT_SECRET: $secret"
```

Copy the printed value — you will need it in the next step.

### 1c. Choose a strong Postgres password

Pick any password that is at least 16 characters and contains no `@` or `/`
characters (those break the connection URL). Example generator:

```powershell
$bytes2 = New-Object byte[] 12
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes2)
$pass = [System.Convert]::ToBase64String($bytes2)
Write-Host "DB_PASSWORD: $pass"
```

### 1d. Edit `.env`

Open the file:

```powershell
notepad .env
```

Replace **every placeholder value** as follows — use the values generated above:

```
POSTGRES_USER=ite
POSTGRES_PASSWORD=<password from 1c>
POSTGRES_DB=ite

ITE_DATABASE_URL=postgresql+psycopg://ite:<same password from 1c>@postgres:5432/ite
ITE_ENV=production
ITE_JWT_SECRET=<secret from 1b>

ITE_ALLOWED_ORIGINS=http://localhost
```

> If other PCs on the same network need access, also find this machine's IP
> (`ipconfig` → look for IPv4 Address under the active adapter) and append it:
> `ITE_ALLOWED_ORIGINS=http://localhost,http://192.168.X.X`

Save and close Notepad.

### 1e. Verify no defaults remain

```powershell
$c = Get-Content .env -Raw
if ($c -match "changeme" -or $c -match "dev-only-change-me") {
    Write-Error "Default secrets still in .env — edit the file and re-run this check."
} else {
    Write-Host "OK — no default secrets found." -ForegroundColor Green
}
```

**Expected:** `OK — no default secrets found.`

---

## Step 2 — Run the setup script

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

> This must run **as Administrator**. If you get an access-denied error, right-click
> `setup-windows.ps1` → "Run as administrator" instead.

The script will print progress for each step:

| Step | What it does | Typical duration |
|------|-------------|-----------------|
| `[0]` | Docker preflight check | instant |
| `[1]` | Validates `.env` has no defaults | instant |
| `[2]` | Loads API + web Docker images | 1–3 min |
| `[3]` | Starts PostgreSQL, waits healthy | 15–30 s |
| `[4]` | Restores database (all history) | 5–15 s |
| `[5]` | Restores certificate files | 10–30 s |
| `[6]` | Starts all services | 10–20 s |

**Expected final output:**
```
==================================================
   Setup complete!
==================================================

   Application:  http://localhost
```

If the script exits with an error at any step, copy the full error message and
stop. Do not proceed.

---

## Step 3 — Verify the installation

### 3a. All four containers are running

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}"
```

**Expected — four rows, all `Up`, postgres and api marked `(healthy)`:**
```
NAMES                        STATUS
ite-calibration-edge-1       Up X seconds
ite-calibration-web-1        Up X seconds
ite-calibration-api-1        Up X seconds (healthy)
ite-calibration-postgres-1   Up X seconds (healthy)
```

If `api` is `(unhealthy)` wait 30 seconds and re-run. If it stays unhealthy
after 2 minutes, run `docker logs ite-calibration-api-1 --tail=40` and report.

### 3b. API health endpoint responds

```powershell
Invoke-RestMethod http://localhost/api/health | ConvertTo-Json
```

**Expected:**
```json
{
  "status": "ok",
  "api": "ok",
  "storage": "ok"
}
```

If `storage` is `"error: ..."`, the certificate volume was not mounted
correctly — stop and report.

### 3c. Frontend loads

```powershell
(Invoke-WebRequest http://localhost/ -UseBasicParsing).Content.Substring(0,100)
```

**Expected:** starts with `<!DOCTYPE html>`

### 3d. Historical calibration data is present

```powershell
docker exec ite-calibration-postgres-1 psql -U ite -d ite -c `
  "SELECT batch_name, status FROM calibration_runs ORDER BY created_at DESC LIMIT 5;"
```

**Expected:** at least one row with `status = complete`.

---

## Step 4 — Manual browser smoke test

1. Open `http://localhost` in Edge or Chrome.
2. Log in with the admin credentials (ask the person who handed you this package).
3. Click **History** — you should see completed calibration runs listed.
4. Click into one run → **Run Detail** should show per-setpoint deviation data.
5. Click **Download (.docx)** on any certificate → file should download.

If any of these fail, stop and report what you see on screen.

---

## Step 5 — Schedule automatic backups

Open **Task Scheduler** (search in Start Menu) and create a task:

```
Name:        ITE Calibration Backup
Trigger:     Daily at 02:00
Action:      Start a program
  Program:   powershell.exe
  Arguments: -ExecutionPolicy Bypass -File "C:\path\to\deploy-package\backup-windows.ps1"
  Start in:  C:\path\to\deploy-package\
```

Replace `C:\path\to\deploy-package\` with the actual path to this folder.

### Verify the backup runs manually

```powershell
powershell -ExecutionPolicy Bypass -File .\backup-windows.ps1
```

**Expected:**
```
[<timestamp>] Starting backup → C:\ite-calibration-backups\<date>
  Dumping database... done (X.X MB)
  Backing up certificate volume... done (XX MB)
[<timestamp>] Backup complete → C:\ite-calibration-backups\<date>
```

Check that the folder was created:

```powershell
Get-ChildItem C:\ite-calibration-backups
```

---

## Step 6 — Confirm auto-restart on reboot (optional but recommended)

Docker Desktop starts automatically with Windows by default. All containers
have `restart: unless-stopped`, so they come back after a reboot without any
manual action.

To test: reboot the PC, wait 2 minutes, then re-run Step 3a and 3b.

---

## Useful commands for later

```powershell
# View live logs
docker compose logs -f

# Stop the app
docker compose down

# Start the app again
docker compose up -d

# Check status
docker ps --filter "name=ite-calibration"
```

---

## Rollback / uninstall

To completely remove the app and all data:

```powershell
docker compose down -v          # stops containers AND deletes volumes
docker rmi ite-calibration-api:latest ite-calibration-web:latest
```

> Warning: `-v` permanently deletes all database and certificate data.
> Only run this if you want a clean slate.
