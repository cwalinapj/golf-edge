from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.session import SessionModel
from backend.app.schemas.session import SessionResponse, SessionStartRequest
from backend.app.services.orchestrator import OrchestratorService

router = APIRouter(prefix="/sessions", tags=["sessions"])
service = OrchestratorService()


@router.post("/start", response_model=SessionResponse)
def start_session(payload: SessionStartRequest, db: Session = Depends(get_db)):
    session = service.start_session(db, payload.mode, payload.location_label)
    return SessionResponse.model_validate(session, from_attributes=True)


@router.post("/{session_id}/stop", response_model=SessionResponse)
def stop_session(session_id: str, db: Session = Depends(get_db)):
    session = db.get(SessionModel, session_id)
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")
    session = service.stop_session(db, session)
    return SessionResponse.model_validate(session, from_attributes=True)
