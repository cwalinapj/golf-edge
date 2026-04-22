from fastapi import APIRouter

from backend.app.schemas.proxy import (
    LaunchMonitorBindingRequest,
    LaunchMonitorBindingResponse,
    LaunchMonitorNetwork,
    LaunchMonitorScanResponse,
    ProxyStatusResponse,
)
from backend.app.services.launch_monitor_network import LaunchMonitorNetworkManager

router = APIRouter(prefix="/proxy", tags=["proxy"])
network_manager = LaunchMonitorNetworkManager()


@router.get("/status", response_model=ProxyStatusResponse)
def proxy_status():
    return ProxyStatusResponse(
        status="unconfigured",
        mevo_connected=False,
        client_connected=False,
        packets_seen=0,
        last_observation_at=None,
        detail="GolfSimRAS adapter is not wired yet.",
    )


@router.get("/launch-monitor/scan", response_model=LaunchMonitorScanResponse)
def scan_launch_monitors(
    station_interface: str = "eth1",
):
    result = network_manager.scan(station_interface=station_interface)
    return LaunchMonitorScanResponse(
        station_interface=station_interface,
        networks=[
            LaunchMonitorNetwork(
                ssid=network.ssid,
                bssid=network.bssid,
                level=network.level,
                frequency=network.frequency,
                capabilities=network.capabilities,
            )
            for network in result.networks
        ],
        detail=result.detail,
    )


@router.post("/launch-monitor/bind", response_model=LaunchMonitorBindingResponse)
def bind_launch_monitor(payload: LaunchMonitorBindingRequest):
    result = network_manager.bind(
        ssid=payload.ssid,
        bssid=payload.bssid,
        passphrase=payload.passphrase,
        station_interface=payload.station_interface,
        keep_connected=payload.keep_connected,
    )
    return LaunchMonitorBindingResponse(
        status=result.status,
        ssid=payload.ssid,
        bssid=payload.bssid,
        station_interface=payload.station_interface,
        keep_connected=payload.keep_connected,
        detail=result.detail,
        connected=result.status == "connected",
    )
