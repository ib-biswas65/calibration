"""Local-disk file store for calibration run artifacts."""

import hashlib
import re
import uuid
from pathlib import Path


def _safe_name(original: str) -> str:
    """Strip path components and replace non-word chars to prevent traversal."""
    name = Path(original).name
    return re.sub(r"[^\w.\-]", "_", name)[:200]


def save_file(data: bytes, *, run_id: uuid.UUID, sub: str, original_name: str, data_dir: Path) -> tuple[Path, str]:
    """Write `data` to <data_dir>/runs/<run_id>/<sub>/<uuid>__<safe_name>.

    Returns (stored_path, sha256_hex).
    """
    sha256 = hashlib.sha256(data).hexdigest()
    file_id = uuid.uuid4()
    safe = _safe_name(original_name)
    dest_dir = data_dir / "runs" / str(run_id) / sub
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{file_id}__{safe}"
    dest.write_bytes(data)
    return dest, sha256


def cert_path(*, run_id: uuid.UUID, result_id: uuid.UUID, cert_no: str, data_dir: Path) -> Path:
    """Return the canonical path for a certificate .docx (directory created)."""
    d = data_dir / "runs" / str(run_id) / "certificates"
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{result_id}__{cert_no}.docx"
