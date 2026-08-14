"""Fix doc_date_jp to re-derive from certificate_date column

doc_date_jp was stored with corrupted characters ('??' instead of 年月日)
in the original runs.  Re-derive it from the certificate_date date column
using the same approach as migration 0005 did for test_date_jp.

Revision ID: 0006_fix_doc_date_jp
Revises: 0005_fix_test_date_jp
Create Date: 2026-06-09 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op

revision: str = "0006_fix_doc_date_jp"
down_revision: Union[str, None] = "0005_fix_test_date_jp"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Re-derive doc_date_jp from the stored certificate_date (a proper date column).
    op.execute(
        """
        UPDATE calibration_runs
        SET doc_date_jp =
            EXTRACT(YEAR  FROM certificate_date)::int::text || '年' ||
            EXTRACT(MONTH FROM certificate_date)::int::text || '月' ||
            EXTRACT(DAY   FROM certificate_date)::int::text || '日'
        """
    )


def downgrade() -> None:
    # Cannot reliably reverse — no-op.
    pass
