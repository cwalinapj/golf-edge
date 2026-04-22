import httpx

from backend.app.services.launch_monitor_network import LaunchMonitorNetworkManager


def test_scan_delegates_to_esp32_control_api(monkeypatch):
    def fake_get(url, timeout):
        assert url == "http://esp32.local/wifi/scan"
        assert timeout == 30.0
        return httpx.Response(
            200,
            request=httpx.Request("GET", url),
            json={
                "networks": [
                    {
                        "ssid": "railgolf",
                        "bssid": "11:22:33:44:55:66",
                        "rssi": -20,
                        "frequency": 2412,
                        "security": "WPA2",
                    },
                    {
                        "ssid": "FS M2-041799",
                        "bssid": "AA:BB:CC:DD:EE:FF",
                        "rssi": -41,
                        "frequency": 2412,
                        "security": "WPA2",
                    }
                ]
            },
        )

    monkeypatch.setattr(httpx, "get", fake_get)

    result = LaunchMonitorNetworkManager("http://esp32.local").scan(
        station_interface="eth1"
    )

    assert result.networks[0].ssid == "FS M2-041799"
    assert result.networks[0].level == -41
    assert result.networks[0].capabilities == "WPA2"
    assert all(network.ssid != "railgolf" for network in result.networks)


def test_bind_reports_wrong_passcode_from_esp32(monkeypatch):
    def fake_post(url, json, timeout):
        assert url == "http://esp32.local/wifi/bind"
        assert json["ssid"] == "FS M2-041799"
        assert json["station_mac"] == "02:11:22:33:44:55"
        assert timeout == 60.0
        return httpx.Response(
            200,
            request=httpx.Request("POST", url),
            json={"connected": False, "detail": "Wrong passcode please try again."},
        )

    monkeypatch.setattr(httpx, "post", fake_post)

    result = LaunchMonitorNetworkManager("http://esp32.local").bind(
        ssid="FS M2-041799",
        bssid="AA:BB:CC:DD:EE:FF",
        passphrase="bad-passcode",
        station_mac="02:11:22:33:44:55",
        station_interface="eth1",
        keep_connected=True,
    )

    assert result.status == "failed"
    assert result.detail == "Wrong passcode please try again."
