from pydantic import BaseModel


class SetupApRequest(BaseModel):
    interface: str = "wlan0"
    ssid: str = "railgolf"
    password: str = "password"
    connection_name: str = "railgolf-control-ap"


class NetworkModeResponse(BaseModel):
    status: str
    detail: str


class Wlan0DhcpRequest(BaseModel):
    interface: str = "wlan0"
