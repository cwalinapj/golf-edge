from sqlalchemy import Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class RoundHoleStateModel(Base):
    __tablename__ = "round_hole_states"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    round_id: Mapped[str] = mapped_column(ForeignKey("rounds.id"), nullable=False)
    hole_id: Mapped[str] = mapped_column(ForeignKey("holes.id"), nullable=False)
    hole_number: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String, nullable=False, default="UPCOMING")
    strokes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    penalties: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    putts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    guidance_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    last_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    arrival_source: Mapped[str | None] = mapped_column(String, nullable=True)
