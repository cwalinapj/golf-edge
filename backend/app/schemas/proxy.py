from datetime import datetime

from pydantic import BaseModel


class ProxyStatusResponse(BaseModel):
    status: str
    mevo_connected: bool
    client_connected: bool
    packets_seen: int
    last_observation_at: datetime | None = None
    detail: str | None = None


class LaunchMonitorBindingRequest(BaseModel):
    ssid: str
    bssid: str
    passphrase: str
    capabilities: str = ""
    owner_key: str
    station_interface: str = "eth1"
    keep_connected: bool = True


class LaunchMonitorNetwork(BaseModel):
    ssid: str
    bssid: str
    level: int
    frequency: int
    capabilities: str = ""


class LaunchMonitorScanResponse(BaseModel):
    station_interface: str
    networks: list[LaunchMonitorNetwork]
    detail: str | None = None


class LaunchMonitorBindingResponse(BaseModel):
    status: str
    ssid: str
    bssid: str
    station_interface: str
    keep_connected: bool
    detail: str
    connected: bool
