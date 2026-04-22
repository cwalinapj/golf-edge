import shutil
import subprocess

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
    def scan(self, *, station_interface: str) -> LaunchMonitorScanResult:
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

    def bind(
        self,
        *,
        ssid: str,
        bssid: str,
        passphrase: str,
        station_interface: str,
        keep_connected: bool,
    ) -> LaunchMonitorNetworkResult:
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
