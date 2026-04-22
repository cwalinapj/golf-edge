from pydantic import BaseModel


class NetworkModeResponse(BaseModel):
    status: str
    detail: str


class Wlan0DhcpRequest(BaseModel):
    interface: str = "wlan0"


class AdminWifiNetwork(BaseModel):
    ssid: str
    bssid: str
    level: int
    frequency: int
    security: str = ""


class AdminWifiScanResponse(BaseModel):
    interface: str
    networks: list[AdminWifiNetwork]
    detail: str | None = None


class AdminWifiCredentialRequest(BaseModel):
    ssid: str
    password: str
    bssid: str | None = None
    interface: str = "wlan0"
    save: bool = True


class AdminWifiCredentialResponse(BaseModel):
    status: str
    detail: str
    ssid: str
    bssid: str | None = None
    interface: str
    saved: bool = False
