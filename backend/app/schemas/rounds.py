from datetime import datetime

from pydantic import BaseModel


class RoundStartRequest(BaseModel):
    course_id: str | None = None
    location_label: str | None = None


class RoundControlUpdateRequest(BaseModel):
    selected_club: str | None = None
    radar_to_ball_distance: float | None = None
    ball_type: str | None = None
    tee_used: str | None = None
    tee_height: str | None = None
    swing_type: str | None = None


class RoundShotCreateRequest(BaseModel):
    hole_number: int | None = None
    club_used: str | None = None
    lie: str | None = None
    penalties: int = 0
    putts: int = 0
    notes: str | None = None
    tee_used: str | None = None
    tee_height: str | None = None
    ball_type: str | None = None
    swing_type: str | None = None
    target_distance: float | None = None
    mevo_observation_id: str | None = None


class RoundLocationUpdateRequest(BaseModel):
    latitude: float
    longitude: float
    source: str = "foreground_gps"


class CurrentHoleUpdateRequest(BaseModel):
    hole_number: int
    source: str = "manual"


class RoundShotResponse(BaseModel):
    id: str
    hole_number: int
    sequence_number: int
    created_at: datetime
    club_used: str | None = None
    lie: str | None = None
    penalties: int
    putts: int
    notes: str | None = None
    tee_used: str | None = None
    tee_height: str | None = None
    ball_type: str | None = None
    swing_type: str | None = None
    target_distance: float | None = None
    mevo_observation_id: str | None = None
    suggestion_source: str | None = None


class RoundControlStateResponse(BaseModel):
    selected_club: str | None = None
    radar_to_ball_distance: float | None = None
    ball_type: str | None = None
    tee_used: str | None = None
    tee_height: str | None = None
    swing_type: str | None = None
    updated_at: datetime


class RoundHoleStateResponse(BaseModel):
    hole_number: int
    par: int
    yardage: int
    status: str
    strokes: int
    penalties: int
    putts: int
    notes: str | None = None
    guidance_summary: str | None = None
    fairway_aim: str | None = None
    hazard_summary: str | None = None
    tee_latitude: float
    tee_longitude: float
    green_latitude: float
    green_longitude: float


class RoundGuidanceResponse(BaseModel):
    message: str
    source: str
    current_hole_number: int
    next_hole_number: int | None = None


class RoundSummaryResponse(BaseModel):
    total_strokes: int
    total_penalties: int
    total_putts: int


class RoundWorkspaceResponse(BaseModel):
    round_id: str
    session_id: str
    status: str
    started_at: datetime
    current_hole_number: int
    current_hole_status: str
    course_name: str
    hole_states: list[RoundHoleStateResponse]
    recent_shots: list[RoundShotResponse]
    controls: RoundControlStateResponse
    guidance: RoundGuidanceResponse
    summary: RoundSummaryResponse


class RoundResponse(BaseModel):
    round_id: str
    session_id: str
    status: str
    current_hole_number: int
    current_hole_status: str
