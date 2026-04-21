from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class RoundControlStateModel(Base):
    __tablename__ = "round_control_states"

    round_id: Mapped[str] = mapped_column(ForeignKey("rounds.id"), primary_key=True)
    selected_club: Mapped[str | None] = mapped_column(String, nullable=True)
    radar_to_ball_distance: Mapped[float | None] = mapped_column(Float, nullable=True)
    ball_type: Mapped[str | None] = mapped_column(String, nullable=True)
    tee_used: Mapped[str | None] = mapped_column(String, nullable=True)
    tee_height: Mapped[str | None] = mapped_column(String, nullable=True)
    swing_type: Mapped[str | None] = mapped_column(String, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
