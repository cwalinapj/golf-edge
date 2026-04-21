from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class RoundModel(Base):
    __tablename__ = "rounds"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    session_id: Mapped[str] = mapped_column(ForeignKey("sessions.id"), nullable=False)
    course_id: Mapped[str] = mapped_column(ForeignKey("courses.id"), nullable=False)
    status: Mapped[str] = mapped_column(String, nullable=False, default="ACTIVE")
    started_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    current_hole_number: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    current_hole_status: Mapped[str] = mapped_column(String, nullable=False, default="ACTIVE")
