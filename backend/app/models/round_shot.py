from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class RoundShotModel(Base):
    __tablename__ = "round_shots"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    round_id: Mapped[str] = mapped_column(ForeignKey("rounds.id"), nullable=False)
    hole_state_id: Mapped[str] = mapped_column(ForeignKey("round_hole_states.id"), nullable=False)
    hole_number: Mapped[int] = mapped_column(Integer, nullable=False)
    sequence_number: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    club_used: Mapped[str | None] = mapped_column(String, nullable=True)
    lie: Mapped[str | None] = mapped_column(String, nullable=True)
    penalties: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    putts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    tee_used: Mapped[str | None] = mapped_column(String, nullable=True)
    tee_height: Mapped[str | None] = mapped_column(String, nullable=True)
    ball_type: Mapped[str | None] = mapped_column(String, nullable=True)
    swing_type: Mapped[str | None] = mapped_column(String, nullable=True)
    target_distance: Mapped[float | None] = mapped_column(Float, nullable=True)
    mevo_observation_id: Mapped[str | None] = mapped_column(ForeignKey("mevo_observations.id"), nullable=True)
    suggestion_source: Mapped[str | None] = mapped_column(String, nullable=True)
