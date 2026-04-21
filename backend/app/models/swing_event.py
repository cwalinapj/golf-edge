from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class SwingEventModel(Base):
    __tablename__ = "swing_events"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    session_id: Mapped[str] = mapped_column(ForeignKey("sessions.id"), nullable=False)
    state: Mapped[str] = mapped_column(String, nullable=False, default="DRAFT")
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    event_time: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    club: Mapped[str | None] = mapped_column(String, nullable=True)
    shot_type: Mapped[str | None] = mapped_column(String, nullable=True)
    target_distance: Mapped[float | None] = mapped_column(Float, nullable=True)
    intent_tag: Mapped[str | None] = mapped_column(String, nullable=True)
    hole_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lie: Mapped[str | None] = mapped_column(String, nullable=True)

    mevo_observation_id: Mapped[str | None] = mapped_column(String, nullable=True)
    oak_clip_id: Mapped[str | None] = mapped_column(String, nullable=True)
    environment_sample_id: Mapped[str | None] = mapped_column(String, nullable=True)
