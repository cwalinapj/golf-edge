from __future__ import annotations

from uuid import uuid4

from sqlalchemy.orm import Session

from backend.app.models.mevo_observation import MevoObservationModel
from backend.app.services.mevo_rf.frame_decoder import DecodedShot


class MevoPublisher:
    def persist_observation(self, db: Session, shot: DecodedShot) -> MevoObservationModel:
        obs = MevoObservationModel(
            id=str(uuid4()),
            decoder_version=shot.decoder_version,
            captured_at=shot.captured_at,
            ball_speed=shot.ball_speed,
            club_speed=shot.club_speed,
            smash_factor=shot.smash_factor,
            carry=shot.carry,
            total=shot.total,
            launch_angle=shot.launch_angle,
            launch_direction=shot.launch_direction,
            spin_rate=shot.spin_rate,
            spin_axis=shot.spin_axis,
            apex_height=shot.apex_height,
            offline=shot.offline,
            confidence=shot.confidence,
        )
        db.add(obs)
        db.commit()
        db.refresh(obs)
        return obs
