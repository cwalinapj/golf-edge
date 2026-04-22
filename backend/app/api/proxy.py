from fastapi import APIRouter

from backend.app.schemas.proxy import (
    LaunchMonitorBindingRequest,
    LaunchMonitorBindingResponse,
    LaunchMonitorNetwork,
    LaunchMonitorScanResponse,
    ProxyConnection,
    ProxyConnectionsResponse,
    ProxyControlRequest,
    ProxyControlResponse,
    ProxyDiscoveryResponse,
    ProxyLogEntry,
    ProxyLogsResponse,
    ProxyStatusResponse,
)
from backend.app.services.launch_monitor_network import LaunchMonitorNetworkManager
from backend.app.services.proxy_brain import ProxyBrain

router = APIRouter(prefix="/proxy", tags=["proxy"])
network_manager = LaunchMonitorNetworkManager()
proxy_brain = ProxyBrain()


@router.get("/status", response_model=ProxyStatusResponse)
def proxy_status():
    return ProxyStatusResponse(**proxy_brain.status())


@router.post("/start", response_model=ProxyControlResponse)
def start_proxy(payload: ProxyControlRequest):
    result = proxy_brain.start(
        runtime_ssid=payload.runtime_ssid,
        runtime_password=payload.runtime_password,
        runtime_bssid=payload.runtime_bssid,
        runtime_channel=payload.runtime_channel,
    )
    return ProxyControlResponse(
        status="started" if result.ok else "failed",
        detail=result.detail,
    )


@router.post("/stop", response_model=ProxyControlResponse)
def stop_proxy():
    result = proxy_brain.stop()
    return ProxyControlResponse(
        status="stopped" if result.ok else "failed",
        detail=result.detail,
    )


@router.get("/mevo", response_model=ProxyDiscoveryResponse)
def get_mevo_info():
    return ProxyDiscoveryResponse(**proxy_brain.discovery())


@router.get("/discovery", response_model=ProxyDiscoveryResponse)
def get_discovery():
    return ProxyDiscoveryResponse(**proxy_brain.discovery())


@router.get("/connections", response_model=ProxyConnectionsResponse)
def get_proxy_connections():
    return ProxyConnectionsResponse(
        connections=[
            ProxyConnection(
                name=connection.name,
                connected=connection.connected,
                detail=connection.detail,
            )
            for connection in proxy_brain.connections()
        ]
    )


@router.get("/logs", response_model=ProxyLogsResponse)
def get_proxy_logs():
    return ProxyLogsResponse(entries=[ProxyLogEntry(**entry) for entry in proxy_brain.logs()])


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
        station_mac=payload.station_mac,
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
