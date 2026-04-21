from __future__ import annotations

from sqlalchemy.orm import Session

from backend.app.models.mevo_observation import MevoObservationModel
from backend.app.models.swing_event import SwingEventModel


class EventMatcherService:
    VALID_STATES = {"DRAFT", "ARMED"}

    def match_mevo_to_latest_open_event(
        self,
        db: Session,
        observation: MevoObservationModel,
    ) -> SwingEventModel | None:
        event = (
            db.query(SwingEventModel)
            .filter(SwingEventModel.state.in_(self.VALID_STATES))
            .order_by(SwingEventModel.created_at.desc())
            .first()
        )
        if event is None:
            return None

        event.mevo_observation_id = observation.id
        event.event_time = observation.captured_at
        event.state = "MEVO_RECEIVED"
        db.add(event)
        db.commit()
        db.refresh(event)
        return event
