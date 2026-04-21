from pydantic import BaseModel


class HoleResponse(BaseModel):
    id: str
    number: int
    par: int
    yardage: int
    tee_latitude: float
    tee_longitude: float
    green_latitude: float
    green_longitude: float
    fairway_aim: str | None = None
    hazard_summary: str | None = None


class CourseResponse(BaseModel):
    id: str
    name: str
    region: str | None = None
    holes: list[HoleResponse]


class CourseListResponse(BaseModel):
    items: list[CourseResponse]
