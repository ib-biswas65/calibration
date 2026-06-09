"""Replace corrupted '??' sequences in batch_name with middle dot separator

Batch names created before the UTF-8 client_encoding fix had any multi-byte
character (Japanese separators, special punctuation) silently replaced with '??'
(two ASCII question marks, 0x3F 0x3F) at the database connection layer.
We cannot recover the original character, so we replace '??' with '·'
(middle dot U+00B7) to make names readable.  Admins can then rename batches
to the correct text via the UI.

Revision ID: 0007_fix_batch_names
Revises: 0006_fix_doc_date_jp
Create Date: 2026-06-09 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op

revision: str = "0007_fix_batch_names"
down_revision: Union[str, None] = "0006_fix_doc_date_jp"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        r"""
        UPDATE calibration_runs
        SET batch_name = replace(batch_name, '??', '·')
        WHERE batch_name LIKE '%??%'
        """
    )


def downgrade() -> None:
    # Cannot recover original characters — no-op.
    pass
