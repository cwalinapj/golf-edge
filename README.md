# Rail Golf

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
flutter run --dart-define=RAIL_GOLF_API_BASE_URL=http://192.168.4.1:8000
```

The default API URL is `http://192.168.4.1:8000`, the Pi address on the `railgolf` controller AP. For emulator development against a backend on the development machine, override it with `--dart-define=RAIL_GOLF_API_BASE_URL=http://10.0.2.2:8000`.

Launch monitor scan and bind requests are routed through the Pi API to the ESP32
control endpoint on the Pi's `eth1` transport. Override the ESP32 control URL on
the Pi with `ESP32_CONTROL_URL` if firmware uses a different USB-NCM address.

See [`docs/android_app_architecture.md`](docs/android_app_architecture.md) for
the Android module split across dashboard, proxy control, FS Golf automation,
recipes, logs, and shared core layers.

The native Kotlin/Compose multi-module scaffold lives in `rail-golf-android/`.
Build it with:

```bash
../tablet_app/android/gradlew -p rail-golf-android assembleDebug
```
