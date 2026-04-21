from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.schemas.swing_event import SwingEventCreateRequest, SwingEventResponse
from backend.app.services.orchestrator import OrchestratorService

router = APIRouter(prefix="/events", tags=["events"])
service = OrchestratorService()


@router.post("/{session_id}", response_model=SwingEventResponse)
def create_event(session_id: str, payload: SwingEventCreateRequest, db: Session = Depends(get_db)):
    event = service.create_event_draft(
        db=db,
        session_id=session_id,
        club=payload.club,
        shot_type=payload.shot_type,
        target_distance=payload.target_distance,
        intent_tag=payload.intent_tag,
        hole_number=payload.hole_number,
        lie=payload.lie,
    )
    return SwingEventResponse.model_validate(event, from_attributes=True)
