# golf-edge

```
Repo layout v.01

golf-edge/
├── README.md
├── pyproject.toml
├── .env.example
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── logging.py
│   │   │   └── events.py
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── init_db.py
│   │   ├── models/
│   │   │   ├── session.py
│   │   │   ├── swing_event.py
│   │   │   ├── mevo_observation.py
│   │   │   ├── environment_sample.py
│   │   │   └── oak_clip.py
│   │   ├── schemas/
│   │   │   ├── session.py
│   │   │   ├── swing_event.py
│   │   │   ├── mevo.py
│   │   │   └── sensors.py
│   │   ├── services/
│   │   │   ├── orchestrator.py
│   │   │   ├── event_matcher.py
│   │   │   ├── sensor_service.py
│   │   │   ├── oak_service.py
│   │   │   └── recommendation_service.py
│   │   ├── services/mevo_rf/
│   │   │   ├── sniffer.py
│   │   │   ├── packet_parser.py
│   │   │   ├── frame_decoder.py
│   │   │   ├── shot_reconstructor.py
│   │   │   └── publisher.py
│   │   ├── api/
│   │   │   ├── sessions.py
│   │   │   ├── events.py
│   │   │   ├── sensors.py
│   │   │   ├── mevo.py
│   │   │   └── ws.py
│   │   └── tests/
│   │       ├── test_event_matcher.py
│   │       └── test_state_machine.py
│   └── scripts/
│       └── dev_run.sh
├── tablet_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── core/
│       │   ├── api_client.dart
│       │   ├── ws_client.dart
│       │   └── models.dart
│       ├── features/
│       │   ├── dashboard/
│       │   ├── sessions/
│       │   ├── swings/
│       │   └── review/
│       └── widgets/
│           ├── status_bar.dart
│           ├── shot_entry_card.dart
│           └── live_metrics_card.dart
└── deployments/
    ├── systemd/
    │   ├── golf-edge-api.service
    │   └── golf-edge-sensors.service
    └── docker/
        └── docker-compose.yml
