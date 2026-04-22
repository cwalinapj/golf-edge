# Golf Edge

Local-first golf analytics and coaching system for Raspberry Pi 5.

## Features
- Live Mevo RF ingest on Pi
- Swing event orchestration
- OAK camera clip attachment
- Environmental sensor snapshots
- Android tablet control UI
- Arccos reconciliation for round outcomes

## Modes
- Practice mode: Mevo + OAK + sensors
- Round mode: Mevo + Arccos + OAK + sensors

## Quick start
1. Create virtualenv
2. Install dependencies
3. Copy `.env.example` to `.env`
4. Run database init
5. Start API

## Development
```bash
uv venv
source .venv/bin/activate
uv pip install -e .
python -m backend.app.db.init_db
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

## Tablet app
```bash
cd tablet_app
flutter pub get
flutter run --dart-define=GOLF_EDGE_API_BASE_URL=http://<pi-ip>:8000
```

The default API URL is `http://10.0.2.2:8000`, which is useful for the Android emulator talking to a backend on the development machine.
