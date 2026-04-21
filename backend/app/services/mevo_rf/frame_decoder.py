from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class DecodedShot:
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


class FrameDecoder:
    decoder_version = "mevo_rf_v0_1_0"

    def decode_frame(self, frame: bytes) -> DecodedShot:
        del frame
        # TODO: Replace stub with your reverse-engineered field mapping.
        return DecodedShot(
            decoder_version=self.decoder_version,
            captured_at=datetime.now(timezone.utc),
            ball_speed=None,
            club_speed=None,
            confidence=0.5,
        )
