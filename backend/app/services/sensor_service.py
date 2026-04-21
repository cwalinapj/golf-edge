from __future__ import annotations

import random
from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class SensorSnapshot:
    captured_at: datetime
    temperature_c: float | None
    humidity_pct: float | None
    pressure_hpa: float | None


class SensorService:
    def read_snapshot(self) -> SensorSnapshot:
        # Replace with real BME280/BME680 read logic.
        return SensorSnapshot(
            captured_at=datetime.now(timezone.utc),
            temperature_c=20.0 + random.random(),
            humidity_pct=50.0 + random.random(),
            pressure_hpa=1013.0 + random.random(),
        )
