from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.schemas.mevo import MevoObservationIn
from backend.app.services.event_matcher import EventMatcherService
from backend.app.services.mevo_rf.frame_decoder import DecodedShot
from backend.app.services.mevo_rf.publisher import MevoPublisher

router = APIRouter(prefix="/mevo", tags=["mevo"])
publisher = MevoPublisher()
matcher = EventMatcherService()


@router.post("/observations")
def ingest_mevo_observation(payload: MevoObservationIn, db: Session = Depends(get_db)):
    shot = DecodedShot(**payload.model_dump())
    observation = publisher.persist_observation(db, shot)
    matched_event = matcher.match_mevo_to_latest_open_event(db, observation)
    return {
        "observation_id": observation.id,
        "matched_event_id": matched_event.id if matched_event else None,
    }
