from datetime import datetime

from pydantic import BaseModel


class SwingEventCreateRequest(BaseModel):
    club: str | None = None
    shot_type: str | None = None
    target_distance: float | None = None
    intent_tag: str | None = None
    hole_number: int | None = None
    lie: str | None = None


class SwingEventResponse(BaseModel):
    id: str
    session_id: str
    state: str
    created_at: datetime
    event_time: datetime | None = None
    club: str | None = None
    shot_type: str | None = None
    target_distance: float | None = None
    intent_tag: str | None = None
