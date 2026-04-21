from datetime import datetime

from pydantic import BaseModel


class MevoObservationIn(BaseModel):
    decoder_version: str
    captured_at: datetime
    ball_speed: float | None = None
    club_speed: float | None = None
    smash_factor: float | None = None
    carry: float | None = None
    total: float | None = None
    launch_angle: float | None = None
    launch_direction: float | None = None
    spin_rate: float | None = None
    spin_axis: float | None = None
    apex_height: float | None = None
    offline: float | None = None
    confidence: float | None = None
