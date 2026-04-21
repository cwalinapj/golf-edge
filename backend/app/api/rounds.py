from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.schemas.rounds import (
    CurrentHoleUpdateRequest,
    RoundControlStateResponse,
    RoundControlUpdateRequest,
    RoundLocationUpdateRequest,
    RoundResponse,
    RoundShotCreateRequest,
    RoundShotResponse,
    RoundStartRequest,
    RoundWorkspaceResponse,
)
from backend.app.services.rounds import RoundService

router = APIRouter(prefix="/rounds", tags=["rounds"])
service = RoundService()


@router.post("/start", response_model=RoundResponse)
def start_round(payload: RoundStartRequest, db: Session = Depends(get_db)):
    try:
        return service.start_round(db, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/{round_id}/workspace", response_model=RoundWorkspaceResponse)
def get_round_workspace(round_id: str, db: Session = Depends(get_db)):
    try:
        return service.get_workspace(db, round_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{round_id}/controls", response_model=RoundControlStateResponse)
def update_round_controls(
    round_id: str,
    payload: RoundControlUpdateRequest,
    db: Session = Depends(get_db),
):
    try:
        return service.update_controls(db, round_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{round_id}/shots", response_model=RoundShotResponse)
def record_round_shot(
    round_id: str,
    payload: RoundShotCreateRequest,
    db: Session = Depends(get_db),
):
    try:
        return service.record_shot(db, round_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{round_id}/location", response_model=RoundResponse)
def update_round_location(
    round_id: str,
    payload: RoundLocationUpdateRequest,
    db: Session = Depends(get_db),
):
    try:
        return service.update_location(db, round_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{round_id}/current-hole", response_model=RoundResponse)
def update_current_hole(
    round_id: str,
    payload: CurrentHoleUpdateRequest,
    db: Session = Depends(get_db),
):
    try:
        return service.update_current_hole(db, round_id, payload.hole_number, payload.source)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{round_id}/holes/{hole_number}/complete", response_model=RoundResponse)
def complete_round_hole(
    round_id: str,
    hole_number: int,
    db: Session = Depends(get_db),
):
    try:
        return service.complete_hole(db, round_id, hole_number)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
