from importlib import import_module

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from backend.app.db.base import Base
from backend.app.db.init_db import MODEL_MODULES
from backend.app.db.session import get_db
from backend.app.main import app


def _create_test_client() -> tuple[TestClient, sessionmaker]:
    for module_path in MODEL_MODULES:
        import_module(module_path)

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        future=True,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    return TestClient(app), TestingSessionLocal


def test_round_workspace_supports_manual_first_flow():
    client, _ = _create_test_client()

    courses = client.get("/courses").json()["items"]
    assert courses

    round_response = client.post("/rounds/start", json={}).json()
    round_id = round_response["round_id"]

    controls = client.post(
        f"/rounds/{round_id}/controls",
        json={
            "selected_club": "7-iron",
            "radar_to_ball_distance": 154,
            "ball_type": "RCT",
            "tee_used": "Blue",
            "tee_height": "1.75 in",
            "swing_type": "full swing",
        },
    ).json()
    assert controls["selected_club"] == "7-iron"

    shot = client.post(
        f"/rounds/{round_id}/shots",
        json={
            "lie": "fairway",
            "putts": 2,
            "penalties": 1,
            "notes": "Front pin with wind off the left.",
        },
    ).json()
    assert shot["club_used"] == "7-iron"
    assert shot["suggestion_source"] == "round_controls"

    workspace = client.get(f"/rounds/{round_id}/workspace").json()
    first_hole = workspace["hole_states"][0]
    assert workspace["current_hole_number"] == 1
    assert workspace["controls"]["ball_type"] == "RCT"
    assert workspace["summary"] == {
        "total_strokes": 1,
        "total_penalties": 1,
        "total_putts": 2,
    }
    assert first_hole["strokes"] == 1
    assert "Hole 1" in workspace["guidance"]["message"]

    app.dependency_overrides.clear()


def test_round_hole_updates_support_location_and_completion_state():
    client, _ = _create_test_client()

    round_response = client.post("/rounds/start", json={}).json()
    round_id = round_response["round_id"]

    courses = client.get("/courses").json()["items"]
    second_hole = courses[0]["holes"][1]

    location_response = client.post(
        f"/rounds/{round_id}/location",
        json={
            "latitude": second_hole["tee_latitude"],
            "longitude": second_hole["tee_longitude"],
            "source": "foreground_gps",
        },
    ).json()
    assert location_response["current_hole_number"] == 2

    manual_response = client.post(
        f"/rounds/{round_id}/current-hole",
        json={"hole_number": 18, "source": "manual"},
    ).json()
    assert manual_response["current_hole_number"] == 18

    completed_response = client.post(f"/rounds/{round_id}/holes/18/complete").json()
    assert completed_response["status"] == "COMPLETED"
    assert completed_response["current_hole_status"] == "ROUND_COMPLETE"

    app.dependency_overrides.clear()
