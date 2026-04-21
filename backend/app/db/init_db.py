from importlib import import_module

from backend.app.db.base import Base
from backend.app.db.session import engine

MODEL_MODULES = (
    "backend.app.models.course",
    "backend.app.models.environment_sample",
    "backend.app.models.hole",
    "backend.app.models.mevo_observation",
    "backend.app.models.round",
    "backend.app.models.round_control_state",
    "backend.app.models.round_hole_state",
    "backend.app.models.round_shot",
    "backend.app.models.session",
    "backend.app.models.swing_event",
)


def init_db() -> None:
    for module_path in MODEL_MODULES:
        import_module(module_path)
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    init_db()
    print("database initialized")
