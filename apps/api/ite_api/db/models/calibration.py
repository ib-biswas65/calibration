import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from ite_api.db.base import Base


class Logger(Base):
    __tablename__ = "loggers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    serial_no: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    model: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    next_due_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class CalibrationRun(Base):
    __tablename__ = "calibration_runs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_name: Mapped[str] = mapped_column(String(200), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="draft")
    testing_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    testing_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    certificate_date: Mapped[date] = mapped_column(Date, nullable=False)
    threshold_c: Mapped[float] = mapped_column(Numeric(5, 3), nullable=False, default=0.5)
    setpoints: Mapped[dict] = mapped_column(JSONB, nullable=False, default=list)
    template_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    failure_reason: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    start_cert_no: Mapped[str] = mapped_column(String(20), nullable=False, default="0000001000")
    cert_width: Mapped[int] = mapped_column(nullable=False, default=10)
    test_date_jp: Mapped[str] = mapped_column(String(30), nullable=False)
    doc_date_jp: Mapped[str] = mapped_column(String(30), nullable=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class RunReferenceFile(Base):
    __tablename__ = "run_reference_files"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("calibration_runs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    stored_path: Mapped[str] = mapped_column(Text, nullable=False)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class RunCalibrationFile(Base):
    __tablename__ = "run_calibration_file"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("calibration_runs.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    stored_path: Mapped[str] = mapped_column(Text, nullable=False)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    sheet_names: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class LoggerResult(Base):
    __tablename__ = "logger_results"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("calibration_runs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    logger_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("loggers.id", ondelete="SET NULL"), nullable=True
    )
    sheet_name: Mapped[str] = mapped_column(String(200), nullable=False)
    verdict: Mapped[str] = mapped_column(String(20), nullable=False)
    max_deviation_c: Mapped[float | None] = mapped_column(Numeric(6, 3), nullable=True)
    per_setpoint: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    cert_no: Mapped[str | None] = mapped_column(String(20), nullable=True)
    cert_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
