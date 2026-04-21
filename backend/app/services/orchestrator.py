from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy.orm import Session

from backend.app.models.session import SessionModel
from backend.app.models.swing_event import SwingEventModel


class OrchestratorService:
    def start_session(self, db: Session, mode: str, location_label: str | None) -> SessionModel:
        session = SessionModel(
            id=str(uuid4()),
            mode=mode,
            status="active",
            started_at=datetime.now(timezone.utc),
            location_label=location_label,
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    def stop_session(self, db: Session, session: SessionModel) -> SessionModel:
        session.status = "completed"
        session.ended_at = datetime.now(timezone.utc)
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    def create_event_draft(
        self,
        db: Session,
        session_id: str,
        club: str | None,
        shot_type: str | None,
        target_distance: float | None,
        intent_tag: str | None,
        hole_number: int | None,
        lie: str | None,
    ) -> SwingEventModel:
        event = SwingEventModel(
            id=str(uuid4()),
            session_id=session_id,
            state="DRAFT",
            created_at=datetime.now(timezone.utc),
            club=club,
            shot_type=shot_type,
            target_distance=target_distance,
            intent_tag=intent_tag,
            hole_number=hole_number,
            lie=lie,
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        return event
