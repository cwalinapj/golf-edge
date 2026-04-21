from fastapi import APIRouter

from backend.app.services.sensor_service import SensorService

router = APIRouter(prefix="/sensors", tags=["sensors"])
service = SensorService()


@router.get("/current")
def current_sensor_snapshot():
    snapshot = service.read_snapshot()
    return {
        "captured_at": snapshot.captured_at.isoformat(),
        "temperature_c": snapshot.temperature_c,
        "humidity_pct": snapshot.humidity_pct,
        "pressure_hpa": snapshot.pressure_hpa,
    }
