"""Reference logger CSV loading — supports multiple files and auto-format detection."""

from pathlib import Path


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
