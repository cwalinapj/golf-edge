from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.schemas.course import CourseListResponse, CourseResponse, HoleResponse
from backend.app.services.rounds import RoundService

router = APIRouter(prefix="/courses", tags=["courses"])
service = RoundService()


@router.get("", response_model=CourseListResponse)
def list_courses(db: Session = Depends(get_db)):
    courses = service.list_courses(db)
    items = []
    for course in courses:
        hole_models = service.course_map_service.get_holes_for_course(db, course.id)
        items.append(
            CourseResponse(
                id=course.id,
                name=course.name,
                region=course.region,
                holes=[
                    HoleResponse(
                        id=hole.id,
                        number=hole.number,
                        par=hole.par,
                        yardage=hole.yardage,
                        tee_latitude=hole.tee_latitude,
                        tee_longitude=hole.tee_longitude,
                        green_latitude=hole.green_latitude,
                        green_longitude=hole.green_longitude,
                        fairway_aim=hole.fairway_aim,
                        hazard_summary=hole.hazard_summary,
                    )
                    for hole in hole_models
                ],
            )
        )
    return CourseListResponse(items=items)
