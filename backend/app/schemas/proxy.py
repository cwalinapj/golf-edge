from datetime import datetime

from pydantic import BaseModel, Field


class ProxyStatusResponse(BaseModel):
    status: str
    mevo_connected: bool
    client_connected: bool
    packets_seen: int
    last_observation_at: datetime | None = None
    detail: str | None = None
    mevo_ip: str | None = None
    client_interface: str | None = None
    mevo_interface: str | None = None
    open_ports: list[int] = Field(default_factory=list)
    last_discovery_response: dict | None = None


class ProxyControlRequest(BaseModel):
    runtime_ssid: str | None = None
    runtime_password: str | None = None
    runtime_bssid: str | None = None
    runtime_channel: int | None = None


class ProxyControlResponse(BaseModel):
    status: str
    detail: str


class ProxyDiscoveryResponse(BaseModel):
    last_response: dict | None = None
    detail: str | None = None


class ProxyConnection(BaseModel):
    name: str
    connected: bool
    detail: str | None = None


class ProxyConnectionsResponse(BaseModel):
    connections: list[ProxyConnection]


class ProxyLogEntry(BaseModel):
    captured_at: datetime
    level: str
    message: str


class ProxyLogsResponse(BaseModel):
    entries: list[ProxyLogEntry]


class LaunchMonitorBindingRequest(BaseModel):
    ssid: str
    bssid: str
    passphrase: str
    capabilities: str = ""
    owner_key: str
    station_mac: str | None = None
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
