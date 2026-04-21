from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import func
from sqlalchemy.orm import Session

from backend.app.models.course import CourseModel
from backend.app.models.hole import HoleModel
from backend.app.models.mevo_observation import MevoObservationModel
from backend.app.models.round import RoundModel
from backend.app.models.round_control_state import RoundControlStateModel
from backend.app.models.round_hole_state import RoundHoleStateModel
from backend.app.models.round_shot import RoundShotModel
from backend.app.models.session import SessionModel
from backend.app.schemas.rounds import (
    RoundControlStateResponse,
    RoundControlUpdateRequest,
    RoundGuidanceResponse,
    RoundHoleStateResponse,
    RoundLocationUpdateRequest,
    RoundResponse,
    RoundShotCreateRequest,
    RoundShotResponse,
    RoundStartRequest,
    RoundSummaryResponse,
    RoundWorkspaceResponse,
)
from backend.app.services.course_map import CourseMapService


class RoundService:
    def __init__(self, course_map_service: CourseMapService | None = None) -> None:
        self.course_map_service = course_map_service or CourseMapService()

    def list_courses(self, db: Session) -> list[CourseModel]:
        return self.course_map_service.list_courses(db)

    def start_round(self, db: Session, payload: RoundStartRequest) -> RoundResponse:
        course = self._resolve_course(db, payload.course_id)
        session = SessionModel(
            id=str(uuid4()),
            mode="round",
            status="active",
            started_at=datetime.now(timezone.utc),
            location_label=payload.location_label or course.name,
        )
        db.add(session)
        round_model = RoundModel(
            id=str(uuid4()),
            session_id=session.id,
            course_id=course.id,
            status="ACTIVE",
            started_at=datetime.now(timezone.utc),
            current_hole_number=1,
            current_hole_status="ACTIVE",
        )
        db.add(round_model)
        holes = self.course_map_service.get_holes_for_course(db, course.id)
        for hole in holes:
            db.add(self.course_map_service.hole_state_seed(round_model.id, hole))
        db.add(
            RoundControlStateModel(
                round_id=round_model.id,
                updated_at=datetime.now(timezone.utc),
            )
        )
        db.commit()
        return RoundResponse(
            round_id=round_model.id,
            session_id=session.id,
            status=round_model.status,
            current_hole_number=round_model.current_hole_number,
            current_hole_status=round_model.current_hole_status,
        )

    def get_workspace(self, db: Session, round_id: str) -> RoundWorkspaceResponse:
        round_model = self._get_round(db, round_id)
        course = db.get(CourseModel, round_model.course_id)
        if course is None:
            raise ValueError("Course not found")
        hole_lookup = {hole.number: hole for hole in self.course_map_service.get_holes_for_course(db, course.id)}
        hole_states = self._get_hole_states(db, round_id)
        hole_count = len(hole_states)
        controls = self._get_controls(db, round_id)
        recent_shots = self._get_recent_shots(db, round_id)
        latest_shot = recent_shots[0] if recent_shots else None
        observation = None
        if latest_shot and latest_shot.mevo_observation_id:
            observation = db.get(MevoObservationModel, latest_shot.mevo_observation_id)
        current_hole_state = self._get_current_hole_state(db, round_model)
        current_hole = hole_lookup[current_hole_state.hole_number]
        guidance_message, guidance_source = self.course_map_service.build_guidance(
            current_hole,
            current_hole_state,
            latest_shot,
            observation,
        )
        current_hole_state.guidance_summary = guidance_message
        db.add(current_hole_state)
        db.commit()
        return RoundWorkspaceResponse(
            round_id=round_model.id,
            session_id=round_model.session_id,
            status=round_model.status,
            started_at=round_model.started_at,
            current_hole_number=round_model.current_hole_number,
            current_hole_status=round_model.current_hole_status,
            course_name=course.name,
            hole_states=[
                self._hole_state_response(hole_state, hole_lookup[hole_state.hole_number])
                for hole_state in hole_states
            ],
            recent_shots=[self._shot_response(shot) for shot in recent_shots],
            controls=RoundControlStateResponse(
                selected_club=controls.selected_club,
                radar_to_ball_distance=controls.radar_to_ball_distance,
                ball_type=controls.ball_type,
                tee_used=controls.tee_used,
                tee_height=controls.tee_height,
                swing_type=controls.swing_type,
                updated_at=controls.updated_at,
            ),
            guidance=RoundGuidanceResponse(
                message=guidance_message,
                source=guidance_source,
                current_hole_number=current_hole_state.hole_number,
                next_hole_number=(
                    current_hole_state.hole_number + 1
                    if current_hole_state.hole_number < hole_count
                    else None
                ),
            ),
            summary=RoundSummaryResponse(
                total_strokes=sum(hole_state.strokes for hole_state in hole_states),
                total_penalties=sum(hole_state.penalties for hole_state in hole_states),
                total_putts=sum(hole_state.putts for hole_state in hole_states),
            ),
        )

    def update_controls(
        self,
        db: Session,
        round_id: str,
        payload: RoundControlUpdateRequest,
    ) -> RoundControlStateResponse:
        controls = self._get_controls(db, round_id)
        for field in (
            "selected_club",
            "radar_to_ball_distance",
            "ball_type",
            "tee_used",
            "tee_height",
            "swing_type",
        ):
            value = getattr(payload, field)
            if value is not None:
                setattr(controls, field, value)
        controls.updated_at = datetime.now(timezone.utc)
        db.add(controls)
        db.commit()
        db.refresh(controls)
        return RoundControlStateResponse(
            selected_club=controls.selected_club,
            radar_to_ball_distance=controls.radar_to_ball_distance,
            ball_type=controls.ball_type,
            tee_used=controls.tee_used,
            tee_height=controls.tee_height,
            swing_type=controls.swing_type,
            updated_at=controls.updated_at,
        )

    def record_shot(
        self,
        db: Session,
        round_id: str,
        payload: RoundShotCreateRequest,
    ) -> RoundShotResponse:
        round_model = self._get_round(db, round_id)
        controls = self._get_controls(db, round_id)
        hole_state = self._get_target_hole_state(db, round_model, payload.hole_number)
        latest_sequence_number = (
            db.query(func.max(RoundShotModel.sequence_number))
            .filter(RoundShotModel.hole_state_id == hole_state.id)
            .scalar()
        )
        shot = RoundShotModel(
            id=str(uuid4()),
            round_id=round_id,
            hole_state_id=hole_state.id,
            hole_number=hole_state.hole_number,
            sequence_number=(latest_sequence_number or 0) + 1,
            created_at=datetime.now(timezone.utc),
            club_used=payload.club_used or controls.selected_club,
            lie=payload.lie,
            penalties=payload.penalties,
            putts=payload.putts,
            notes=payload.notes,
            tee_used=payload.tee_used or controls.tee_used,
            tee_height=payload.tee_height or controls.tee_height,
            ball_type=payload.ball_type or controls.ball_type,
            swing_type=payload.swing_type or controls.swing_type,
            target_distance=payload.target_distance or controls.radar_to_ball_distance,
            mevo_observation_id=payload.mevo_observation_id,
            suggestion_source="round_controls" if payload.club_used is None else None,
        )
        db.add(shot)

        hole_state.strokes += 1
        hole_state.penalties += payload.penalties
        hole_state.putts += payload.putts
        if payload.notes:
            hole_state.notes = payload.notes
        hole_state.status = "PENDING_SHOT_ATTRIBUTION" if payload.mevo_observation_id is None else "ACTIVE"
        round_model.current_hole_status = hole_state.status
        db.add(hole_state)
        db.add(round_model)
        db.commit()
        db.refresh(shot)
        return self._shot_response(shot)

    def update_current_hole(self, db: Session, round_id: str, hole_number: int, source: str) -> RoundResponse:
        round_model = self._get_round(db, round_id)
        hole_state = self._get_target_hole_state(db, round_model, hole_number)
        self._set_current_hole(round_model, hole_state, source)
        db.add(round_model)
        db.add(hole_state)
        db.commit()
        return RoundResponse(
            round_id=round_model.id,
            session_id=round_model.session_id,
            status=round_model.status,
            current_hole_number=round_model.current_hole_number,
            current_hole_status=round_model.current_hole_status,
        )

    def update_location(
        self,
        db: Session,
        round_id: str,
        payload: RoundLocationUpdateRequest,
    ) -> RoundResponse:
        round_model = self._get_round(db, round_id)
        holes = self.course_map_service.get_holes_for_course(db, round_model.course_id)
        inferred_hole = self.course_map_service.infer_hole_for_location(
            holes,
            payload.latitude,
            payload.longitude,
        )
        hole_state = self._get_target_hole_state(db, round_model, inferred_hole.number)
        hole_state.last_latitude = payload.latitude
        hole_state.last_longitude = payload.longitude
        self._set_current_hole(round_model, hole_state, payload.source)
        db.add(round_model)
        db.add(hole_state)
        db.commit()
        return RoundResponse(
            round_id=round_model.id,
            session_id=round_model.session_id,
            status=round_model.status,
            current_hole_number=round_model.current_hole_number,
            current_hole_status=round_model.current_hole_status,
        )

    def complete_hole(self, db: Session, round_id: str, hole_number: int) -> RoundResponse:
        round_model = self._get_round(db, round_id)
        hole_state = self._get_target_hole_state(db, round_model, hole_number)
        total_holes = len(self._get_hole_states(db, round_id))
        hole_state.status = "HOLE_COMPLETE"
        db.add(hole_state)
        if hole_number >= total_holes:
            round_model.status = "COMPLETED"
            round_model.current_hole_status = "ROUND_COMPLETE"
            round_model.completed_at = datetime.now(timezone.utc)
            session = db.get(SessionModel, round_model.session_id)
            if session is not None:
                session.status = "completed"
                session.ended_at = round_model.completed_at
                db.add(session)
        else:
            next_hole_state = self._get_target_hole_state(db, round_model, hole_number + 1)
            self._set_current_hole(round_model, next_hole_state, "hole_complete")
            db.add(next_hole_state)
        db.add(round_model)
        db.commit()
        return RoundResponse(
            round_id=round_model.id,
            session_id=round_model.session_id,
            status=round_model.status,
            current_hole_number=round_model.current_hole_number,
            current_hole_status=round_model.current_hole_status,
        )

    def _resolve_course(self, db: Session, course_id: str | None) -> CourseModel:
        self.course_map_service.ensure_seed_data(db)
        if course_id is None:
            course = db.get(CourseModel, "sample-course")
        else:
            course = db.get(CourseModel, course_id)
        if course is None:
            raise ValueError("Course not found")
        return course

    def _get_round(self, db: Session, round_id: str) -> RoundModel:
        round_model = db.get(RoundModel, round_id)
        if round_model is None:
            raise ValueError("Round not found")
        return round_model

    def _get_controls(self, db: Session, round_id: str) -> RoundControlStateModel:
        controls = db.get(RoundControlStateModel, round_id)
        if controls is None:
            controls = RoundControlStateModel(
                round_id=round_id,
                updated_at=datetime.now(timezone.utc),
            )
            db.add(controls)
            db.commit()
            db.refresh(controls)
        return controls

    def _get_hole_states(self, db: Session, round_id: str) -> list[RoundHoleStateModel]:
        return (
            db.query(RoundHoleStateModel)
            .filter(RoundHoleStateModel.round_id == round_id)
            .order_by(RoundHoleStateModel.hole_number.asc())
            .all()
        )

    def _get_current_hole_state(self, db: Session, round_model: RoundModel) -> RoundHoleStateModel:
        return self._get_target_hole_state(db, round_model, round_model.current_hole_number)

    def _get_target_hole_state(
        self,
        db: Session,
        round_model: RoundModel,
        hole_number: int | None,
    ) -> RoundHoleStateModel:
        target_number = hole_number or round_model.current_hole_number
        hole_state = (
            db.query(RoundHoleStateModel)
            .filter(
                RoundHoleStateModel.round_id == round_model.id,
                RoundHoleStateModel.hole_number == target_number,
            )
            .first()
        )
        if hole_state is None:
            raise ValueError("Hole state not found")
        return hole_state

    def _get_recent_shots(self, db: Session, round_id: str) -> list[RoundShotModel]:
        return (
            db.query(RoundShotModel)
            .filter(RoundShotModel.round_id == round_id)
            .order_by(RoundShotModel.created_at.desc())
            .limit(8)
            .all()
        )

    def _set_current_hole(
        self,
        round_model: RoundModel,
        hole_state: RoundHoleStateModel,
        source: str,
    ) -> None:
        round_model.current_hole_number = hole_state.hole_number
        round_model.current_hole_status = "ACTIVE"
        if hole_state.status == "UPCOMING":
            hole_state.status = "ACTIVE"
        hole_state.arrival_source = source

    def _shot_response(self, shot: RoundShotModel) -> RoundShotResponse:
        return RoundShotResponse(
            id=shot.id,
            hole_number=shot.hole_number,
            sequence_number=shot.sequence_number,
            created_at=shot.created_at,
            club_used=shot.club_used,
            lie=shot.lie,
            penalties=shot.penalties,
            putts=shot.putts,
            notes=shot.notes,
            tee_used=shot.tee_used,
            tee_height=shot.tee_height,
            ball_type=shot.ball_type,
            swing_type=shot.swing_type,
            target_distance=shot.target_distance,
            mevo_observation_id=shot.mevo_observation_id,
            suggestion_source=shot.suggestion_source,
        )

    def _hole_state_response(
        self,
        hole_state: RoundHoleStateModel,
        hole: HoleModel,
    ) -> RoundHoleStateResponse:
        return RoundHoleStateResponse(
            hole_number=hole_state.hole_number,
            par=hole.par,
            yardage=hole.yardage,
            status=hole_state.status,
            strokes=hole_state.strokes,
            penalties=hole_state.penalties,
            putts=hole_state.putts,
            notes=hole_state.notes,
            guidance_summary=hole_state.guidance_summary,
            fairway_aim=hole.fairway_aim,
            hazard_summary=hole.hazard_summary,
            tee_latitude=hole.tee_latitude,
            tee_longitude=hole.tee_longitude,
            green_latitude=hole.green_latitude,
            green_longitude=hole.green_longitude,
        )
