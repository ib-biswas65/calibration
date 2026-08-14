"""add missing indexes on logger_results

Revision ID: b7e2d3f4a8c1
Revises: a3f1b2c4d5e6
Create Date: 2026-05-28 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op

revision: str = 'b7e2d3f4a8c1'
down_revision: Union[str, None] = 'a3f1b2c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # logger_id is a FK queried in get_logger() history lookups — needs an index.
    op.create_index('ix_logger_results_logger_id', 'logger_results', ['logger_id'], unique=False)
    # cert_no is queried in find_by_cert_no() — needs an index for fast lookup.
    op.create_index('ix_logger_results_cert_no', 'logger_results', ['cert_no'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_logger_results_cert_no', table_name='logger_results')
    op.drop_index('ix_logger_results_logger_id', table_name='logger_results')
