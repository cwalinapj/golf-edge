from datetime import UTC, datetime

from fastapi.testclient import TestClient

from backend.app.api import proxy
from backend.app.main import app
from backend.app.services.proxy_brain import ProxyCommandResult, ProxyConnectionState


class FakeProxyBrain:
    def __init__(self) -> None:
        self.started_with = None

    def status(self):
        return {
            "status": "running",
            "mevo_connected": True,
            "client_connected": True,
            "packets_seen": 7,
            "last_observation_at": datetime.now(UTC),
            "detail": "ok",
            "mevo_ip": "192.168.2.1",
            "client_interface": "wlan1",
            "mevo_interface": "eth1",
            "open_ports": [5100, 1258],
            "last_discovery_response": {"ssid": "FS M2-041799"},
        }

    def start(self, **kwargs):
        self.started_with = kwargs
        return ProxyCommandResult(ok=True, detail="runtime started")

    def stop(self):
        return ProxyCommandResult(ok=True, detail="runtime stopped")

    def discovery(self):
        return {
            "last_response": {"ssid": "FS M2-041799"},
            "detail": "discovered",
        }

    def connections(self):
        return [
            ProxyConnectionState(name="client_ap", connected=True, detail="station present"),
            ProxyConnectionState(name="tcp_5100", connected=True, detail="192.168.2.1:5100"),
        ]

    def logs(self):
        return [
            {
                "captured_at": datetime.now(UTC),
                "level": "info",
                "message": "runtime started",
            }
        ]


def test_proxy_phase_one_endpoints(monkeypatch):
    fake = FakeProxyBrain()
    monkeypatch.setattr(proxy, "proxy_brain", fake)
    client = TestClient(app)

    status = client.get("/proxy/status").json()
    assert status["status"] == "running"
    assert status["mevo_connected"] is True
    assert status["open_ports"] == [5100, 1258]

    started = client.post(
        "/proxy/start",
        json={"runtime_ssid": "FS M2-041799", "runtime_channel": 6},
    ).json()
    assert started == {"status": "started", "detail": "runtime started"}
    assert fake.started_with["runtime_ssid"] == "FS M2-041799"
    assert fake.started_with["runtime_channel"] == 6

    assert client.post("/proxy/stop").json()["status"] == "stopped"
    assert client.get("/proxy/mevo").json()["last_response"]["ssid"] == "FS M2-041799"
    assert client.get("/proxy/discovery").json()["detail"] == "discovered"
    assert client.get("/proxy/connections").json()["connections"][0]["name"] == "client_ap"
    assert client.get("/proxy/logs").json()["entries"][0]["message"] == "runtime started"
