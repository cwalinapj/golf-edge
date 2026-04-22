# Rail Golf System Plan

Rail Golf is the tablet-facing control layer for a Raspberry Pi 5 edge system. The Pi should own local orchestration, persistence, hardware IO, and the transparent Mevo proxy bridge. The Android app should stay thin: show state, collect operator intent, and invoke Pi APIs.

## Target Topology

- Mevo launch monitor connects through the existing transparent proxy path.
- Raspberry Pi runs the transparent proxy plus the Rail Golf FastAPI backend.
- Android tablet runs the Rail Golf UI and the FS Golf app.
- Rail Golf UI talks to the Pi over HTTP/WebSocket.
- A future Android accessibility service watches and controls FS Golf when direct app integration is unavailable.
- Additional MCUs publish hardware state to the Pi, preferably over USB serial, CAN, or BLE with one normalized sensor/event contract at the backend boundary.

## Backend Responsibilities

- Session lifecycle: practice and round sessions.
- Shot lifecycle: staged intent, Mevo observation match, camera/sensor attachment, resolved result.
- Proxy status: Mevo connection state, FS Golf client connection state, packet counters, last decoded observation.
- Hardware status: MCU health, firmware versions, heartbeat timestamps, sensor snapshots.
- Real-time fanout: WebSocket events for tablet UI updates.

## Android Responsibilities

- Start and stop sessions.
- Stage the next shot with club, lie, target, intent, and hole context.
- Display Pi/proxy/MCU health without requiring SSH.
- Subscribe to WebSocket updates for live Mevo observations and matched events.
- Provide an Android accessibility bridge for FS Golf screen reads/taps only where needed.

## Accessibility Bridge

The FS Golf bridge should be isolated behind a native Android service package so the core tablet UI can still run without accessibility permission. The Flutter app can communicate with that service through a method channel.

Initial bridge contract:

- `fs_golf.status`: permission state, foreground package, current screen label.
- `fs_golf.read_metrics`: best-effort parsed shot metrics from visible UI text.
- `fs_golf.navigate`: named action such as `open_session`, `select_club`, or `return_to_range`.
- `fs_golf.tap`: guarded tap by semantic target, not raw coordinates unless calibrated.

## Proxy Changes

The existing GolfSimRAS proxy should expose a local status/control surface for Rail Golf:

- `GET /proxy/status`
- `POST /proxy/restart`
- `GET /proxy/packets/recent`
- WebSocket event stream for connection changes and decoded Mevo frames.

Packet decoding should remain proxy-side or Pi-side, not in the Android UI.

## First Milestones

1. Make the Flutter app a real Pi dashboard for sessions, staged shots, sensors, and connection state.
2. Add backend proxy status endpoints backed by an adapter around GolfSimRAS.
3. Add WebSocket broadcast from backend services to the tablet app.
4. Add native Android platform scaffold and an accessibility service skeleton.
5. Define MCU message schemas and build one mocked MCU integration test before wiring physical boards.
