from datetime import datetime

from pydantic import BaseModel


class SessionStartRequest(BaseModel):
    mode: str
    location_label: str | None = None


class SessionResponse(BaseModel):
    id: str
    mode: str
    status: str
    started_at: datetime
    ended_at: datetime | None = None
    location_label: str | None = None
