from fastapi import APIRouter

from backend.app.schemas.admin import (
    AdminWifiCredentialRequest,
    AdminWifiCredentialResponse,
    AdminWifiNetwork,
    AdminWifiScanResponse,
    NetworkModeResponse,
    Wlan0DhcpRequest,
)
from backend.app.services.admin_network import AdminNetworkManager

router = APIRouter(prefix="/admin", tags=["admin"])
network_manager = AdminNetworkManager()


@router.post("/wlan0/dhcp-up", response_model=NetworkModeResponse)
def wlan0_dhcp_up(payload: Wlan0DhcpRequest):
    result = network_manager.wlan0_dhcp_up(interface=payload.interface)
    return NetworkModeResponse(status=result.status, detail=result.detail)


@router.get("/wlan0/wifi/scan", response_model=AdminWifiScanResponse)
def scan_wlan0_wifi(interface: str = "wlan0"):
    result = network_manager.scan_wifi(interface=interface)
    return AdminWifiScanResponse(
        interface=interface,
        networks=[
            AdminWifiNetwork(
                ssid=network.ssid,
                bssid=network.bssid,
                level=network.level,
                frequency=network.frequency,
                security=network.security,
            )
            for network in result.networks
        ],
        detail=result.detail,
    )


@router.post("/wlan0/wifi/authenticate", response_model=AdminWifiCredentialResponse)
def authenticate_wlan0_wifi(payload: AdminWifiCredentialRequest):
    result = network_manager.authenticate_and_save_wifi(
        ssid=payload.ssid,
        password=payload.password,
        bssid=payload.bssid,
        interface=payload.interface,
        save=payload.save,
    )
    return AdminWifiCredentialResponse(
        status=result.status,
        detail=result.detail,
        ssid=result.ssid,
        bssid=result.bssid,
        interface=result.interface,
        saved=result.saved,
    )
