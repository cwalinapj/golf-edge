from sqlalchemy import Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class HoleModel(Base):
    __tablename__ = "holes"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    course_id: Mapped[str] = mapped_column(ForeignKey("courses.id"), nullable=False)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    par: Mapped[int] = mapped_column(Integer, nullable=False)
    yardage: Mapped[int] = mapped_column(Integer, nullable=False)
    tee_latitude: Mapped[float] = mapped_column(Float, nullable=False)
    tee_longitude: Mapped[float] = mapped_column(Float, nullable=False)
    green_latitude: Mapped[float] = mapped_column(Float, nullable=False)
    green_longitude: Mapped[float] = mapped_column(Float, nullable=False)
    fairway_aim: Mapped[str | None] = mapped_column(String, nullable=True)
    hazard_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
