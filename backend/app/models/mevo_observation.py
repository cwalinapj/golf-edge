from datetime import datetime

from sqlalchemy import DateTime, Float, String
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class MevoObservationModel(Base):
    __tablename__ = "mevo_observations"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    source: Mapped[str] = mapped_column(String, nullable=False, default="mevo_rf")
    decoder_version: Mapped[str] = mapped_column(String, nullable=False)
    captured_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    ball_speed: Mapped[float | None] = mapped_column(Float, nullable=True)
    club_speed: Mapped[float | None] = mapped_column(Float, nullable=True)
    smash_factor: Mapped[float | None] = mapped_column(Float, nullable=True)
    carry: Mapped[float | None] = mapped_column(Float, nullable=True)
    total: Mapped[float | None] = mapped_column(Float, nullable=True)
    launch_angle: Mapped[float | None] = mapped_column(Float, nullable=True)
    launch_direction: Mapped[float | None] = mapped_column(Float, nullable=True)
    spin_rate: Mapped[float | None] = mapped_column(Float, nullable=True)
    spin_axis: Mapped[float | None] = mapped_column(Float, nullable=True)
    apex_height: Mapped[float | None] = mapped_column(Float, nullable=True)
    offline: Mapped[float | None] = mapped_column(Float, nullable=True)
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
