"""Reference logger CSV loading — supports multiple files and auto-format detection."""

import re
from pathlib import Path

_DATE_FIRST_RE = re.compile(r"^\d{4}[/-]\d{2}[/-]\d{2}")
_DATE_SECOND_RE = re.compile(r"^[^,]+,\d{4}[/-]\d{2}[/-]\d{2}")


def _try_open(path: Path):
    """Open `path` for text reading, trying common Japanese loggers' encodings first."""
    for enc in ("shift_jis", "cp932", "utf-8"):
        try:
            f = open(path, encoding=enc)
            f.read(1)
            f.seek(0)
            return f
        except UnicodeDecodeError:
            continue
    return open(path, encoding="utf-8", errors="replace")


def detect_format(path: Path) -> str:
    """Return 'mc3000' (datetime first field), 'indexed' (datetime second), or 'unknown'."""
    with _try_open(path) as f:
        scanned = 0
        for line in f:
            line = line.strip()
            if not line:
                continue
            if _DATE_FIRST_RE.match(line):
                return "mc3000"
            if _DATE_SECOND_RE.match(line):
                return "indexed"
            scanned += 1
            if scanned >= 200:
                break
    return "unknown"
