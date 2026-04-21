from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from backend.app.db.base import Base


class CourseModel(Base):
    __tablename__ = "courses"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    region: Mapped[str | None] = mapped_column(String, nullable=True)
