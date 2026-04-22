import json
import os
from pathlib import Path
import shutil
import subprocess

from pydantic import BaseModel


class AdminNetworkResult(BaseModel):
    status: str
    detail: str


class AdminWifiNetworkResult(BaseModel):
    ssid: str
    bssid: str
    level: int
    frequency: int
    security: str = ""


class AdminWifiScanResult(BaseModel):
    networks: list[AdminWifiNetworkResult]
    detail: str | None = None


class AdminWifiCredentialResult(BaseModel):
    status: str
    detail: str
    ssid: str
    bssid: str | None = None
    interface: str
    saved: bool = False


class AdminNetworkManager:
    def __init__(self, credential_path: Path | None = None):
        self.credential_path = credential_path or Path(
            os.environ.get(
                "RAIL_GOLF_WIFI_CREDENTIALS",
                "/var/lib/rail-golf/wifi_credentials.json",
            )
        )

    def wlan1_setup_ap_up(
        self,
        *,
        interface: str = "wlan1",
        ssid: str = "railgolf",
        password: str = "password",
        connection_name: str = "railgolf-setup-ap",
    ) -> AdminNetworkResult:
        if len(password) < 8:
            return AdminNetworkResult(
                status="failed",
                detail="Setup AP password must be at least 8 characters.",
            )
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        if not self._connection_exists(nmcli, connection_name):
            add = self._run(
                [
                    nmcli,
                    "connection",
                    "add",
                    "type",
                    "wifi",
                    "ifname",
                    interface,
                    "con-name",
                    connection_name,
                    "autoconnect",
                    "yes",
                    "ssid",
                    ssid,
                ],
            )
            if add.returncode != 0:
                return self._failed(add, "Could not create wlan1 setup AP.")

        modify = self._run(
            [
                nmcli,
                "connection",
                "modify",
                connection_name,
                "connection.interface-name",
                interface,
                "connection.autoconnect",
                "yes",
                "802-11-wireless.ssid",
                ssid,
                "802-11-wireless.mode",
                "ap",
                "802-11-wireless.band",
                "bg",
                "wifi-sec.key-mgmt",
                "wpa-psk",
                "wifi-sec.psk",
                password,
                "ipv4.method",
                "shared",
                "ipv6.method",
                "ignore",
            ],
        )
        if modify.returncode != 0:
            return self._failed(modify, "Could not configure wlan1 setup AP.")

        up = self._run([nmcli, "connection", "up", connection_name], timeout=30)
        if up.returncode != 0:
            return self._failed(up, "Could not activate wlan1 setup AP.")

        return AdminNetworkResult(
            status="wlan1_setup_ap",
            detail=f"Setup AP {ssid} is active on {interface}.",
        )

    def wlan1_bridge_proxy_up(
        self,
        *,
        interface: str = "wlan1",
        setup_connection_name: str = "railgolf-setup-ap",
    ) -> AdminNetworkResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        self._run([nmcli, "connection", "down", setup_connection_name])
        self._run([nmcli, "device", "set", interface, "managed", "yes"])
        link = self._run(["ip", "link", "set", interface, "up"])
        if link.returncode != 0:
            return self._failed(link, f"Could not bring {interface} up for bridge/proxy mode.")
        return AdminNetworkResult(
            status="wlan1_bridge_proxy",
            detail=f"{interface} is ready for bridge/proxy mode.",
        )

    def wlan0_dhcp_up(self, *, interface: str = "wlan0") -> AdminNetworkResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        self._run([nmcli, "device", "set", interface, "managed", "yes"])
        connect = self._run([nmcli, "device", "connect", interface], timeout=30)
        if connect.returncode != 0:
            return self._failed(connect, f"Could not return {interface} to DHCP client mode.")
        return AdminNetworkResult(
            status="dhcp_client",
            detail=f"{interface} is back in DHCP client mode.",
        )

    def scan_wifi(self, *, interface: str = "wlan0") -> AdminWifiScanResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminWifiScanResult(
                networks=[],
                detail="NetworkManager nmcli is not available on this host.",
            )

        self._run([nmcli, "device", "wifi", "rescan", "ifname", interface], timeout=20)
        completed = self._run(
            [
                nmcli,
                "-t",
                "-f",
                "SSID,BSSID,SIGNAL,FREQ,SECURITY",
                "device",
                "wifi",
                "list",
                "ifname",
                interface,
            ],
            timeout=20,
        )
        if completed.returncode != 0:
            return AdminWifiScanResult(
                networks=[],
                detail=completed.stderr.strip()
                or completed.stdout.strip()
                or f"Could not scan Wi-Fi on {interface}.",
            )

        networks = [
            network
            for line in completed.stdout.splitlines()
            if (network := self._parse_nmcli_wifi(line)) is not None
        ]
        networks.sort(key=lambda network: network.level, reverse=True)
        return AdminWifiScanResult(networks=networks)

    def authenticate_and_save_wifi(
        self,
        *,
        ssid: str,
        password: str,
        bssid: str | None = None,
        interface: str = "wlan0",
        save: bool = True,
    ) -> AdminWifiCredentialResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminWifiCredentialResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
                ssid=ssid,
                bssid=bssid,
                interface=interface,
            )

        if not ssid.strip():
            return AdminWifiCredentialResult(
                status="failed",
                detail="SSID is required.",
                ssid=ssid,
                bssid=bssid,
                interface=interface,
            )

        command = [
            nmcli,
            "device",
            "wifi",
            "connect",
            ssid,
            "password",
            password,
            "ifname",
            interface,
        ]
        if bssid:
            command.extend(["bssid", bssid])

        completed = self._run(command, timeout=45)
        if completed.returncode != 0:
            return AdminWifiCredentialResult(
                status="auth_failed",
                detail=completed.stderr.strip()
                or completed.stdout.strip()
                or "Wi-Fi handshake failed. Check the password and try again.",
                ssid=ssid,
                bssid=bssid,
                interface=interface,
            )

        if save:
            self._save_wifi_credential(
                ssid=ssid,
                password=password,
                bssid=bssid,
                interface=interface,
            )

        return AdminWifiCredentialResult(
            status="authenticated",
            detail=f"{interface} authenticated with {ssid}.",
            ssid=ssid,
            bssid=bssid,
            interface=interface,
            saved=save,
        )

    def _nmcli(self) -> str | None:
        return shutil.which("nmcli")

    def _connection_exists(self, nmcli: str, connection_name: str) -> bool:
        completed = self._run([nmcli, "-t", "-f", "NAME", "connection", "show"])
        return connection_name in completed.stdout.splitlines()

    def _run(self, command: list[str], *, timeout: int = 15) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

    def _failed(
        self,
        completed: subprocess.CompletedProcess[str],
        fallback: str,
    ) -> AdminNetworkResult:
        detail = completed.stderr.strip() or completed.stdout.strip() or fallback
        return AdminNetworkResult(status="failed", detail=detail)

    def _save_wifi_credential(
        self,
        *,
        ssid: str,
        password: str,
        bssid: str | None,
        interface: str,
    ) -> None:
        self.credential_path.parent.mkdir(parents=True, exist_ok=True)
        credentials = []
        if self.credential_path.exists():
            try:
                loaded = json.loads(self.credential_path.read_text())
                if isinstance(loaded, list):
                    credentials = loaded
            except json.JSONDecodeError:
                credentials = []

        credentials = [
            item
            for item in credentials
            if not (
                isinstance(item, dict)
                and item.get("ssid") == ssid
                and item.get("interface") == interface
            )
        ]
        credentials.append(
            {
                "ssid": ssid,
                "password": password,
                "bssid": bssid,
                "interface": interface,
            }
        )
        self.credential_path.write_text(json.dumps(credentials, indent=2))
        self.credential_path.chmod(0o600)

    def _parse_nmcli_wifi(self, line: str) -> AdminWifiNetworkResult | None:
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
        return AdminWifiNetworkResult(
            ssid=ssid,
            bssid=bssid,
            level=level,
            frequency=frequency_value,
            security=security,
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
