"""add failure_reason to logger_results

Revision ID: 0008_add_logger_result_failure_reason
Revises: 0007_fix_batch_names
Create Date: 2026-09-15 00:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0008_add_logger_result_failure_reason"
down_revision: str | None = "0007_fix_batch_names"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Set when verdict == "invalid": why no certificate could be generated for this
    # logger (e.g. no reference reading within tolerance for one or more setpoints).
    op.add_column("logger_results", sa.Column("failure_reason", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("logger_results", "failure_reason")
