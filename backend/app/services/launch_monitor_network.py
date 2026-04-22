from __future__ import annotations

from typing import Any

import httpx
from pydantic import BaseModel

from backend.app.core.config import settings


class LaunchMonitorNetworkResult(BaseModel):
    status: str
    detail: str


class LaunchMonitorScanNetwork(BaseModel):
    ssid: str
    bssid: str
    level: int
    frequency: int
    capabilities: str = ""


class LaunchMonitorScanResult(BaseModel):
    networks: list[LaunchMonitorScanNetwork]
    detail: str | None = None


class LaunchMonitorNetworkManager:
    def __init__(self, control_url: str | None = None) -> None:
        self.control_url = (control_url or settings.esp32_control_url).rstrip("/")

    def scan(self, *, station_interface: str) -> LaunchMonitorScanResult:
        if not station_interface.startswith("eth"):
            return LaunchMonitorScanResult(
                networks=[],
                detail=(
                    "Launch monitor scanning is delegated to the ESP32 over eth1; "
                    f"{station_interface} is not a controller transport."
                ),
            )

        try:
            response = httpx.get(f"{self.control_url}/wifi/scan", timeout=30.0)
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPError as error:
            return LaunchMonitorScanResult(
                networks=[],
                detail=(
                    f"ESP32 control API is not reachable at {self.control_url}: {error}. "
                    "Flash firmware with the /wifi/scan control endpoint before testing Mevo scan."
                ),
            )
        except ValueError:
            return LaunchMonitorScanResult(
                networks=[],
                detail="ESP32 control API returned a non-JSON scan response.",
            )

        raw_networks = payload.get("networks", payload)
        if not isinstance(raw_networks, list):
            return LaunchMonitorScanResult(
                networks=[],
                detail="ESP32 control API scan response did not include a networks list.",
            )

        networks = [
            network
            for item in raw_networks
            if isinstance(item, dict)
            if (network := self._parse_esp32_network(item)) is not None
        ]
        networks.sort(key=lambda network: network.level, reverse=True)
        return LaunchMonitorScanResult(
            networks=networks,
            detail=f"Scanned launch monitors through ESP32 control API on {station_interface}.",
        )

    def bind(
        self,
        *,
        ssid: str,
        bssid: str,
        passphrase: str,
        station_mac: str | None,
        station_interface: str,
        keep_connected: bool,
    ) -> LaunchMonitorNetworkResult:
        if not station_interface.startswith("eth"):
            return LaunchMonitorNetworkResult(
                status="failed",
                detail=(
                    "Launch monitor binding must go through ESP32 control on eth1; "
                    f"{station_interface} is not allowed."
                ),
            )

        payload = {
            "ssid": ssid,
            "bssid": bssid,
            "passphrase": passphrase,
            "keep_connected": keep_connected,
        }
        if station_mac:
            payload["station_mac"] = station_mac
        try:
            response = httpx.post(
                f"{self.control_url}/wifi/bind",
                json=payload,
                timeout=60.0,
            )
            response.raise_for_status()
            result = response.json()
        except httpx.HTTPStatusError as error:
            detail = error.response.text.strip() or str(error)
            return LaunchMonitorNetworkResult(status="failed", detail=detail)
        except httpx.HTTPError as error:
            return LaunchMonitorNetworkResult(
                status="failed",
                detail=(
                    f"ESP32 control API is not reachable at {self.control_url}: {error}. "
                    "Wrong passcode checking will be available after the ESP32 bind endpoint is flashed."
                ),
            )
        except ValueError:
            return LaunchMonitorNetworkResult(
                status="failed",
                detail="ESP32 control API returned a non-JSON bind response.",
            )

        connected = result.get("connected") is True or result.get("status") == "connected"
        detail = str(result.get("detail") or result.get("message") or "")
        if connected:
            return LaunchMonitorNetworkResult(
                status="connected",
                detail=detail or f"ESP32 connected to {ssid} ({bssid}).",
            )
        return LaunchMonitorNetworkResult(
            status="failed",
            detail=detail or "Wrong passcode or launch monitor Wi-Fi connection failed.",
        )

    def _parse_esp32_network(self, item: dict[str, Any]) -> LaunchMonitorScanNetwork | None:
        ssid = str(item.get("ssid") or "")
        bssid = str(item.get("bssid") or item.get("mac") or "")
        if not ssid or not bssid:
            return None

        return LaunchMonitorScanNetwork(
            ssid=ssid,
            bssid=bssid,
            level=self._int_from(item.get("level", item.get("rssi")), default=-100),
            frequency=self._int_from(item.get("frequency", item.get("freq")), default=0),
            capabilities=str(item.get("capabilities") or item.get("security") or ""),
        )

    def _int_from(self, value: Any, *, default: int) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default
