from fastapi import APIRouter

from backend.app.schemas.admin import NetworkModeResponse, SetupApRequest, Wlan0DhcpRequest
from backend.app.services.admin_network import AdminNetworkManager

router = APIRouter(prefix="/admin", tags=["admin"])
network_manager = AdminNetworkManager()


@router.post("/setup-ap/open", response_model=NetworkModeResponse)
def open_setup_ap(payload: SetupApRequest):
    result = network_manager.open_setup_ap(
        interface=payload.interface,
        ssid=payload.ssid,
        password=payload.password,
        connection_name=payload.connection_name,
    )
    return NetworkModeResponse(status=result.status, detail=result.detail)


@router.post("/setup-ap/close", response_model=NetworkModeResponse)
def close_setup_ap(payload: SetupApRequest):
    result = network_manager.close_setup_ap(connection_name=payload.connection_name)
    return NetworkModeResponse(status=result.status, detail=result.detail)


@router.post("/wlan0/dhcp-up", response_model=NetworkModeResponse)
def wlan0_dhcp_up(payload: Wlan0DhcpRequest):
    result = network_manager.wlan0_dhcp_up(interface=payload.interface)
    return NetworkModeResponse(status=result.status, detail=result.detail)
