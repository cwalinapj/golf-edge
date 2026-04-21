from backend.app.db.base import Base
from backend.app.db.session import engine
from backend.app.models.environment_sample import EnvironmentSampleModel
from backend.app.models.mevo_observation import MevoObservationModel
from backend.app.models.session import SessionModel
from backend.app.models.swing_event import SwingEventModel


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    init_db()
    print("database initialized")
