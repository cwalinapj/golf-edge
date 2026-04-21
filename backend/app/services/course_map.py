from __future__ import annotations

from math import inf
from uuid import uuid4

from sqlalchemy.orm import Session

from backend.app.models.course import CourseModel
from backend.app.models.hole import HoleModel
from backend.app.models.mevo_observation import MevoObservationModel
from backend.app.models.round_hole_state import RoundHoleStateModel
from backend.app.models.round_shot import RoundShotModel

SAMPLE_COURSE_ID = "sample-course"
SAMPLE_COURSE_BLUEPRINT = {
    "name": "Sandbox Links",
    "region": "Local Demo Course",
    "holes": [
        {"number": 1, "par": 4, "yardage": 402, "fairway_aim": "Center bunkers", "hazard_summary": "Bunker right at 245, collection area left.", "tee_latitude": 37.4200, "tee_longitude": -122.0840, "green_latitude": 37.4209, "green_longitude": -122.0830},
        {"number": 2, "par": 5, "yardage": 528, "fairway_aim": "Left-center to open the second shot", "hazard_summary": "Cross bunker at 285, creek guards layup zone.", "tee_latitude": 37.4211, "tee_longitude": -122.0832, "green_latitude": 37.4224, "green_longitude": -122.0825},
        {"number": 3, "par": 3, "yardage": 176, "fairway_aim": "Middle of the green", "hazard_summary": "Deep bunker short right, false front.", "tee_latitude": 37.4226, "tee_longitude": -122.0828, "green_latitude": 37.4229, "green_longitude": -122.0821},
        {"number": 4, "par": 4, "yardage": 431, "fairway_aim": "Left half of fairway", "hazard_summary": "Fairway bunker right, native area long left.", "tee_latitude": 37.4232, "tee_longitude": -122.0824, "green_latitude": 37.4241, "green_longitude": -122.0818},
        {"number": 5, "par": 4, "yardage": 389, "fairway_aim": "Favor right rough edge", "hazard_summary": "Fairway bunker left, runoff behind green.", "tee_latitude": 37.4244, "tee_longitude": -122.0816, "green_latitude": 37.4252, "green_longitude": -122.0812},
        {"number": 6, "par": 5, "yardage": 545, "fairway_aim": "Right-center off the tee", "hazard_summary": "Pond left on approach, bunker short right.", "tee_latitude": 37.4255, "tee_longitude": -122.0811, "green_latitude": 37.4268, "green_longitude": -122.0805},
        {"number": 7, "par": 4, "yardage": 418, "fairway_aim": "Short of ridge line", "hazard_summary": "Waste area right, ridge blocks view if too long.", "tee_latitude": 37.4270, "tee_longitude": -122.0807, "green_latitude": 37.4279, "green_longitude": -122.0801},
        {"number": 8, "par": 3, "yardage": 162, "fairway_aim": "Front-middle", "hazard_summary": "Water short left, bailout long right.", "tee_latitude": 37.4282, "tee_longitude": -122.0799, "green_latitude": 37.4284, "green_longitude": -122.0791},
        {"number": 9, "par": 4, "yardage": 446, "fairway_aim": "Inside left tree line", "hazard_summary": "Creek pinches landing zone, bunker back right.", "tee_latitude": 37.4287, "tee_longitude": -122.0794, "green_latitude": 37.4298, "green_longitude": -122.0788},
        {"number": 10, "par": 4, "yardage": 411, "fairway_aim": "Right-center at TV tower", "hazard_summary": "Bunker left, severe slope off right side.", "tee_latitude": 37.4301, "tee_longitude": -122.0787, "green_latitude": 37.4310, "green_longitude": -122.0780},
        {"number": 11, "par": 5, "yardage": 561, "fairway_aim": "Split fairway markers", "hazard_summary": "Creek crosses at 300, green guarded by front bunkers.", "tee_latitude": 37.4312, "tee_longitude": -122.0783, "green_latitude": 37.4325, "green_longitude": -122.0777},
        {"number": 12, "par": 4, "yardage": 403, "fairway_aim": "Left-center plateau", "hazard_summary": "Right rough trees, runoff short left of green.", "tee_latitude": 37.4328, "tee_longitude": -122.0775, "green_latitude": 37.4336, "green_longitude": -122.0769},
        {"number": 13, "par": 3, "yardage": 188, "fairway_aim": "Center green over the bunker", "hazard_summary": "Bunker front center, shelf falls off long.", "tee_latitude": 37.4339, "tee_longitude": -122.0768, "green_latitude": 37.4342, "green_longitude": -122.0760},
        {"number": 14, "par": 4, "yardage": 437, "fairway_aim": "Short grass left of bunker", "hazard_summary": "Fairway bunker right, steep falloff behind green.", "tee_latitude": 37.4345, "tee_longitude": -122.0759, "green_latitude": 37.4356, "green_longitude": -122.0752},
        {"number": 15, "par": 4, "yardage": 392, "fairway_aim": "Aim at lone oak", "hazard_summary": "Native area right, front-left bunker at green.", "tee_latitude": 37.4358, "tee_longitude": -122.0753, "green_latitude": 37.4367, "green_longitude": -122.0747},
        {"number": 16, "par": 5, "yardage": 537, "fairway_aim": "Center cut line", "hazard_summary": "Waste bunker left, water guards right layup.", "tee_latitude": 37.4370, "tee_longitude": -122.0745, "green_latitude": 37.4384, "green_longitude": -122.0740},
        {"number": 17, "par": 3, "yardage": 169, "fairway_aim": "Left-center landing spot", "hazard_summary": "Bunker right, shaved runoff left.", "tee_latitude": 37.4386, "tee_longitude": -122.0738, "green_latitude": 37.4389, "green_longitude": -122.0731},
        {"number": 18, "par": 4, "yardage": 452, "fairway_aim": "Favor the left rough edge", "hazard_summary": "Fairway bunker right, pond left of green.", "tee_latitude": 37.4392, "tee_longitude": -122.0730, "green_latitude": 37.4404, "green_longitude": -122.0724},
    ],
}


class CourseMapService:
    def ensure_seed_data(self, db: Session) -> CourseModel:
        course = db.get(CourseModel, SAMPLE_COURSE_ID)
        if course is not None:
            return course

        course = CourseModel(
            id=SAMPLE_COURSE_ID,
            name=SAMPLE_COURSE_BLUEPRINT["name"],
            region=SAMPLE_COURSE_BLUEPRINT["region"],
        )
        db.add(course)
        for hole_blueprint in SAMPLE_COURSE_BLUEPRINT["holes"]:
            db.add(
                HoleModel(
                    id=f"{SAMPLE_COURSE_ID}-hole-{hole_blueprint['number']}",
                    course_id=course.id,
                    number=hole_blueprint["number"],
                    par=hole_blueprint["par"],
                    yardage=hole_blueprint["yardage"],
                    tee_latitude=hole_blueprint["tee_latitude"],
                    tee_longitude=hole_blueprint["tee_longitude"],
                    green_latitude=hole_blueprint["green_latitude"],
                    green_longitude=hole_blueprint["green_longitude"],
                    fairway_aim=hole_blueprint["fairway_aim"],
                    hazard_summary=hole_blueprint["hazard_summary"],
                )
            )
        db.commit()
        db.refresh(course)
        return course

    def list_courses(self, db: Session) -> list[CourseModel]:
        self.ensure_seed_data(db)
        return db.query(CourseModel).order_by(CourseModel.name.asc()).all()

    def get_holes_for_course(self, db: Session, course_id: str) -> list[HoleModel]:
        return (
            db.query(HoleModel)
            .filter(HoleModel.course_id == course_id)
            .order_by(HoleModel.number.asc())
            .all()
        )

    def infer_hole_for_location(self, holes: list[HoleModel], latitude: float, longitude: float) -> HoleModel:
        nearest_hole: HoleModel | None = None
        nearest_distance = inf
        for hole in holes:
            distance = min(
                self._distance_squared(latitude, longitude, hole.tee_latitude, hole.tee_longitude),
                self._distance_squared(latitude, longitude, hole.green_latitude, hole.green_longitude),
            )
            if distance < nearest_distance:
                nearest_distance = distance
                nearest_hole = hole

        if nearest_hole is None:
            raise ValueError("Unable to infer a hole without course data")
        return nearest_hole

    def build_guidance(
        self,
        hole: HoleModel,
        hole_state: RoundHoleStateModel,
        latest_shot: RoundShotModel | None,
        observation: MevoObservationModel | None,
    ) -> tuple[str, str]:
        if latest_shot and observation and observation.offline is not None and observation.carry is not None:
            finish_direction = "left" if observation.offline < 0 else "right"
            message = (
                f"Favor the {finish_direction} rough edge on hole {hole.number}; "
                f"flight finished about {abs(int(observation.offline))} yards offline "
                f"with {int(observation.carry)} yards of carry."
            )
            return message, "mevo+hole_map"

        if latest_shot:
            message = (
                f"Hole {hole.number}: start from {hole.fairway_aim or 'the center line'}; "
                f"last entry used {latest_shot.club_used or 'manual setup'} and notes should watch "
                f"{hole.hazard_summary or 'the primary landing area'}."
            )
            return message, "hole_map+manual_entry"

        message = (
            f"Hole {hole.number}: {hole.fairway_aim or 'Play the center line'}; "
            f"watch {hole.hazard_summary or 'the landing area'}."
        )
        return message, "hole_map"

    def hole_state_seed(self, round_id: str, hole: HoleModel) -> RoundHoleStateModel:
        return RoundHoleStateModel(
            id=str(uuid4()),
            round_id=round_id,
            hole_id=hole.id,
            hole_number=hole.number,
            status="ACTIVE" if hole.number == 1 else "UPCOMING",
            strokes=0,
            penalties=0,
            putts=0,
        )

    def _distance_squared(
        self,
        latitude: float,
        longitude: float,
        target_latitude: float,
        target_longitude: float,
    ) -> float:
        return ((latitude - target_latitude) ** 2) + ((longitude - target_longitude) ** 2)
