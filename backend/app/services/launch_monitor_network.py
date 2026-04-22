from __future__ import annotations

import ipaddress
import shutil
import socket
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed

from pydantic import BaseModel


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
    def scan(
        self,
        *,
        station_interface: str,
        subnet: str = "192.168.2.0/24",
    ) -> LaunchMonitorScanResult:
        if station_interface.startswith("eth"):
            return self._scan_ethernet_clients(
                station_interface=station_interface,
                subnet=subnet,
            )
        return self._scan_wifi(station_interface=station_interface)

    def _scan_wifi(self, *, station_interface: str) -> LaunchMonitorScanResult:
        nmcli = shutil.which("nmcli")
        if nmcli is None:
            return LaunchMonitorScanResult(
                networks=[],
                detail="NetworkManager nmcli is not available on this host.",
            )

        subprocess.run(
            [nmcli, "device", "wifi", "rescan", "ifname", station_interface],
            check=False,
            capture_output=True,
            text=True,
            timeout=20,
        )
        completed = subprocess.run(
            [
                nmcli,
                "-t",
                "-f",
                "SSID,BSSID,SIGNAL,FREQ,SECURITY",
                "device",
                "wifi",
                "list",
                "ifname",
                station_interface,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=20,
        )
        if completed.returncode != 0:
            detail = completed.stderr.strip() or completed.stdout.strip()
            return LaunchMonitorScanResult(
                networks=[],
                detail=detail or f"Could not scan Wi-Fi on {station_interface}.",
            )

        networks = [
            network
            for line in completed.stdout.splitlines()
            if (network := self._parse_nmcli_network(line)) is not None
        ]
        networks.sort(key=lambda network: network.level, reverse=True)
        return LaunchMonitorScanResult(networks=networks)

    def _scan_ethernet_clients(
        self,
        *,
        station_interface: str,
        subnet: str,
    ) -> LaunchMonitorScanResult:
        try:
            network = ipaddress.ip_network(subnet, strict=False)
        except ValueError as error:
            return LaunchMonitorScanResult(networks=[], detail=f"Invalid subnet: {error}")

        interface_detail = self._interface_detail(station_interface)
        if interface_detail:
            return LaunchMonitorScanResult(networks=[], detail=interface_detail)

        hosts = [str(host) for host in network.hosts()]
        found: list[LaunchMonitorScanNetwork] = []
        with ThreadPoolExecutor(max_workers=48) as executor:
            futures = {
                executor.submit(self._probe_launch_monitor_host, station_interface, host): host
                for host in hosts
            }
            for future in as_completed(futures):
                host = futures[future]
                if future.result():
                    found.append(
                        LaunchMonitorScanNetwork(
                            ssid=f"Launch Monitor {host}",
                            bssid=host,
                            level=0,
                            frequency=0,
                            capabilities="ETHERNET",
                        )
                    )

        found.sort(key=lambda network: network.bssid)
        return LaunchMonitorScanResult(
            networks=found,
            detail=(
                f"Scanned {subnet} on {station_interface}."
                if found
                else f"No launch monitor clients found on {subnet} via {station_interface}."
            ),
        )

    def _interface_detail(self, station_interface: str) -> str | None:
        ip = shutil.which("ip")
        if ip is None:
            return "The ip command is not available on this host."

        completed = subprocess.run(
            [ip, "-4", "-brief", "address", "show", "dev", station_interface],
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
        if completed.returncode != 0 or not completed.stdout.strip():
            return f"{station_interface} is not available."
        if "192.168.2." not in completed.stdout:
            return (
                f"{station_interface} is not on 192.168.2.0/24. "
                "Make sure the ESP32 USB NIC is connected as a DHCP client."
            )
        return None

    def _probe_launch_monitor_host(self, station_interface: str, host: str) -> bool:
        for port in (5100, 80, 443):
            if self._tcp_connect(host, port):
                return True

        arping = shutil.which("arping")
        if arping is None:
            return False

        completed = subprocess.run(
            [arping, "-c", "1", "-w", "1", "-I", station_interface, host],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
        return completed.returncode == 0

    def bind(
        self,
        *,
        ssid: str,
        bssid: str,
        passphrase: str,
        station_interface: str,
        keep_connected: bool,
    ) -> LaunchMonitorNetworkResult:
        if station_interface.startswith("eth"):
            if self._tcp_connect(bssid, 5100):
                return LaunchMonitorNetworkResult(
                    status="connected",
                    detail=f"{station_interface} can reach launch monitor at {bssid}:5100.",
                )
            return LaunchMonitorNetworkResult(
                status="failed",
                detail=f"Could not reach launch monitor at {bssid}:5100 on {station_interface}.",
            )

        nmcli = shutil.which("nmcli")
        if nmcli is None:
            return LaunchMonitorNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        command = [
            nmcli,
            "device",
            "wifi",
            "connect",
            ssid,
            "password",
            passphrase,
            "ifname",
            station_interface,
            "bssid",
            bssid,
        ]

        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=45,
        )

        if completed.returncode != 0:
            detail = completed.stderr.strip() or completed.stdout.strip()
            if not detail:
                detail = "Wrong passcode or launch monitor Wi-Fi connection failed."
            return LaunchMonitorNetworkResult(status="failed", detail=detail)

        if keep_connected:
            self._keep_connection_on_interface(
                nmcli=nmcli,
                ssid=ssid,
                bssid=bssid,
                station_interface=station_interface,
            )

        return LaunchMonitorNetworkResult(
            status="connected",
            detail=f"{station_interface} is connected to {ssid} ({bssid}).",
        )

    def _tcp_connect(self, host: str, port: int) -> bool:
        try:
            with socket.create_connection((host, port), timeout=0.35):
                return True
        except OSError:
            return False

    def _keep_connection_on_interface(
        self,
        *,
        nmcli: str,
        ssid: str,
        bssid: str,
        station_interface: str,
    ) -> None:
        subprocess.run(
            [
                nmcli,
                "connection",
                "modify",
                ssid,
                "connection.autoconnect",
                "yes",
                "connection.interface-name",
                station_interface,
                "802-11-wireless.bssid",
                bssid,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def _parse_nmcli_network(self, line: str) -> LaunchMonitorScanNetwork | None:
        fields = self._split_nmcli_terse(line)
        if len(fields) < 5:
            return None

        ssid, bssid, signal, frequency, security = fields[:5]
        if not ssid or not bssid:
            return None

        try:
            level = int(signal)
        except ValueError:
            level = -100

        try:
            frequency_value = int(frequency)
        except ValueError:
            frequency_value = 0

        return LaunchMonitorScanNetwork(
            ssid=ssid,
            bssid=bssid,
            level=level,
            frequency=frequency_value,
            capabilities=security,
        )

    def _split_nmcli_terse(self, line: str) -> list[str]:
        fields: list[str] = []
        current: list[str] = []
        escaped = False
        for char in line:
            if escaped:
                current.append(char)
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == ":":
                fields.append("".join(current))
                current = []
            else:
                current.append(char)
        fields.append("".join(current))
        return fields
