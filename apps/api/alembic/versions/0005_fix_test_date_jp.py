"""Fix test_date_jp to derive from testing_start, not certificate_date

Previously NewCalibrationPage sent jpDate(certDate) for both test_date_jp and
doc_date_jp, meaning the test date on every certificate was the cert-issue date
rather than the actual testing date.  This migration re-derives test_date_jp from
the testing_start column for all existing runs.

Revision ID: 0005_fix_test_date_jp
Revises: 0004_add_user_pending
Create Date: 2026-06-09 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op

revision: str = "0005_fix_test_date_jp"
down_revision: Union[str, None] = "0004_add_user_pending"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Re-derive test_date_jp from the actual testing_start datetime.
    # EXTRACT returns numeric parts; casting to int drops trailing .0 before concat.
    op.execute(
        """
        UPDATE calibration_runs
        SET test_date_jp =
            EXTRACT(YEAR  FROM testing_start)::int::text || '年' ||
            EXTRACT(MONTH FROM testing_start)::int::text || '月' ||
            EXTRACT(DAY   FROM testing_start)::int::text || '日'
        """
    )


def downgrade() -> None:
    # Best-effort rollback: reset test_date_jp to match doc_date_jp (the old behaviour).
    op.execute(
        """
        UPDATE calibration_runs
        SET test_date_jp = doc_date_jp
        """
    )
