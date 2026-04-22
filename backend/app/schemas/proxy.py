from datetime import datetime

from pydantic import BaseModel


class ProxyStatusResponse(BaseModel):
    status: str
    mevo_connected: bool
    client_connected: bool
    packets_seen: int
    last_observation_at: datetime | None = None
    detail: str | None = None
