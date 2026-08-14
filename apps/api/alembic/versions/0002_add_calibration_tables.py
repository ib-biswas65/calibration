"""add calibration tables

Revision ID: a3f1b2c4d5e6
Revises: 898cc91c1fa1
Create Date: 2026-05-26 14:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = 'a3f1b2c4d5e6'
down_revision: Union[str, None] = '898cc91c1fa1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'loggers',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('serial_no', sa.String(length=100), nullable=False),
        sa.Column('model', sa.String(length=100), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('next_due_at', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_loggers_serial_no'), 'loggers', ['serial_no'], unique=True)

    op.create_table(
        'calibration_runs',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('batch_name', sa.String(length=200), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('testing_start', sa.DateTime(timezone=True), nullable=False),
        sa.Column('testing_end', sa.DateTime(timezone=True), nullable=False),
        sa.Column('certificate_date', sa.Date(), nullable=False),
        sa.Column('threshold_c', sa.Numeric(5, 3), nullable=False),
        sa.Column('setpoints', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('template_path', sa.Text(), nullable=True),
        sa.Column('failure_reason', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('start_cert_no', sa.String(length=20), nullable=False),
        sa.Column('cert_width', sa.Integer(), nullable=False),
        sa.Column('test_date_jp', sa.String(length=30), nullable=False),
        sa.Column('doc_date_jp', sa.String(length=30), nullable=False),
        sa.Column('created_by', sa.UUID(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_calibration_runs_created_at'), 'calibration_runs', ['created_at'], unique=False)
    op.create_index(op.f('ix_calibration_runs_created_by'), 'calibration_runs', ['created_by'], unique=False)

    op.create_table(
        'run_reference_files',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('run_id', sa.UUID(), nullable=False),
        sa.Column('original_name', sa.String(length=255), nullable=False),
        sa.Column('stored_path', sa.Text(), nullable=False),
        sa.Column('sha256', sa.String(length=64), nullable=False),
        sa.Column('uploaded_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['run_id'], ['calibration_runs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_run_reference_files_run_id'), 'run_reference_files', ['run_id'], unique=False)

    op.create_table(
        'run_calibration_file',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('run_id', sa.UUID(), nullable=False),
        sa.Column('original_name', sa.String(length=255), nullable=False),
        sa.Column('stored_path', sa.Text(), nullable=False),
        sa.Column('sha256', sa.String(length=64), nullable=False),
        sa.Column('sheet_names', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('uploaded_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['run_id'], ['calibration_runs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('run_id'),
    )

    op.create_table(
        'logger_results',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('run_id', sa.UUID(), nullable=False),
        sa.Column('logger_id', sa.UUID(), nullable=True),
        sa.Column('sheet_name', sa.String(length=200), nullable=False),
        sa.Column('verdict', sa.String(length=20), nullable=False),
        sa.Column('max_deviation_c', sa.Numeric(6, 3), nullable=True),
        sa.Column('per_setpoint', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('cert_no', sa.String(length=20), nullable=True),
        sa.Column('cert_path', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['logger_id'], ['loggers.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['run_id'], ['calibration_runs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_logger_results_run_id'), 'logger_results', ['run_id'], unique=False)

    # Add FK constraint on audit_log.run_id now that calibration_runs exists
    op.create_foreign_key(
        'fk_audit_log_run_id', 'audit_log', 'calibration_runs', ['run_id'], ['id'], ondelete='SET NULL'
    )


def downgrade() -> None:
    op.drop_constraint('fk_audit_log_run_id', 'audit_log', type_='foreignkey')
    op.drop_index(op.f('ix_logger_results_run_id'), table_name='logger_results')
    op.drop_table('logger_results')
    op.drop_table('run_calibration_file')
    op.drop_index(op.f('ix_run_reference_files_run_id'), table_name='run_reference_files')
    op.drop_table('run_reference_files')
    op.drop_index(op.f('ix_calibration_runs_created_by'), table_name='calibration_runs')
    op.drop_index(op.f('ix_calibration_runs_created_at'), table_name='calibration_runs')
    op.drop_table('calibration_runs')
    op.drop_index(op.f('ix_loggers_serial_no'), table_name='loggers')
    op.drop_table('loggers')
