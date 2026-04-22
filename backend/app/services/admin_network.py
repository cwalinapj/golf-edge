import shutil
import subprocess

from pydantic import BaseModel


class AdminNetworkResult(BaseModel):
    status: str
    detail: str


class AdminNetworkManager:
    def open_setup_ap(
        self,
        *,
        interface: str = "wlan0",
        ssid: str = "railgolf",
        password: str = "password",
        connection_name: str = "railgolf-control-ap",
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
                return self._failed(add, "Could not create setup AP connection.")

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
            return self._failed(modify, "Could not configure setup AP.")

        up = self._run([nmcli, "connection", "up", connection_name], timeout=30)
        if up.returncode != 0:
            return self._failed(up, "Could not activate setup AP.")

        return AdminNetworkResult(
            status="setup_ap_open",
            detail=f"Setup AP {ssid} is active on {interface}.",
        )

    def close_setup_ap(
        self,
        *,
        connection_name: str = "railgolf-control-ap",
    ) -> AdminNetworkResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        down = self._run([nmcli, "connection", "down", connection_name])
        if down.returncode != 0:
            return self._failed(down, "Could not close setup AP.")
        return AdminNetworkResult(
            status="setup_ap_closed",
            detail=f"Setup AP {connection_name} is down.",
        )

    def wlan0_dhcp_up(self, *, interface: str = "wlan0") -> AdminNetworkResult:
        nmcli = self._nmcli()
        if nmcli is None:
            return AdminNetworkResult(
                status="unavailable",
                detail="NetworkManager nmcli is not available on this host.",
            )

        self._run([nmcli, "connection", "down", "railgolf-control-ap"])
        self._run([nmcli, "device", "set", interface, "managed", "yes"])
        connect = self._run([nmcli, "device", "connect", interface], timeout=30)
        if connect.returncode != 0:
            return self._failed(connect, f"Could not return {interface} to DHCP client mode.")
        return AdminNetworkResult(
            status="dhcp_client",
            detail=f"{interface} is back in DHCP client mode.",
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
