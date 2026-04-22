from __future__ import annotations

import socket
import subprocess
from collections import deque
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path

import httpx

from backend.app.core.config import settings


@dataclass(frozen=True)
class ProxyCommandResult:
    ok: bool
    detail: str


@dataclass(frozen=True)
class ProxyConnectionState:
    name: str
    connected: bool
    detail: str | None = None


class ProxyBrain:
    """Pi-side owner for Rail Golf proxy control and observable runtime state."""

    def __init__(
        self,
        *,
        golfsimras_root: str | None = None,
        esp32_control_url: str | None = None,
        client_interface: str | None = None,
        mevo_interface: str | None = None,
        mevo_ip: str | None = None,
        mevo_ports: str | None = None,
        log_limit: int | None = None,
    ) -> None:
        self.golfsimras_root = Path(golfsimras_root or settings.golfsimras_root)
        self.esp32_control_url = (esp32_control_url or settings.esp32_control_url).rstrip("/")
        self.client_interface = client_interface or settings.proxy_client_interface
        self.mevo_interface = mevo_interface or settings.proxy_mevo_interface
        self.mevo_ip = mevo_ip or settings.proxy_mevo_ip
        self.mevo_ports = self._parse_ports(mevo_ports or settings.proxy_mevo_ports)
        self._logs: deque[dict] = deque(maxlen=log_limit or settings.proxy_log_limit)
        self._last_discovery_response: dict | None = None
        self._command_paths = {
            "iptables": self._find_command("iptables", "/usr/sbin/iptables"),
            "iw": self._find_command("iw", "/usr/sbin/iw"),
            "nmcli": self._find_command("nmcli", "/usr/bin/nmcli"),
            "ping": self._find_command("ping", "/usr/bin/ping"),
        }

    def status(self) -> dict:
        esp32_status = self._esp32_status()
        mevo_connected = self._can_connect_any_mevo_port()
        client_connected = bool(self._wlan_clients())
        open_ports = [port for port in self.mevo_ports if self._tcp_connect(self.mevo_ip, port)]
        status = "running" if mevo_connected and client_connected else "partial"
        if not mevo_connected and not client_connected:
            status = "waiting"

        detail = "Proxy runtime is observable from the Pi."
        if esp32_status:
            detail = f"ESP32 status: {esp32_status}"

        return {
            "status": status,
            "mevo_connected": mevo_connected,
            "client_connected": client_connected,
            "packets_seen": self._forwarded_packet_count(),
            "last_observation_at": datetime.now(UTC),
            "detail": detail,
            "mevo_ip": self.mevo_ip,
            "client_interface": self.client_interface,
            "mevo_interface": self.mevo_interface,
            "open_ports": open_ports,
            "last_discovery_response": self._last_discovery_response,
        }

    def start(
        self,
        *,
        runtime_ssid: str | None = None,
        runtime_password: str | None = None,
        runtime_bssid: str | None = None,
        runtime_channel: int | None = None,
    ) -> ProxyCommandResult:
        if not self.golfsimras_root.exists():
            detail = f"GolfSimRAS root does not exist: {self.golfsimras_root}"
            self._log("error", detail)
            return ProxyCommandResult(ok=False, detail=detail)

        command = ["make", "runtime-mode-up"]
        if runtime_ssid:
            command.append(f"RUNTIME_SSID={runtime_ssid}")
        if runtime_password:
            command.append(f"RUNTIME_PASSWORD={runtime_password}")
        if runtime_bssid:
            command.append(f"RUNTIME_BSSID={runtime_bssid}")
        if runtime_channel is not None:
            command.append(f"RUNTIME_CHANNEL={runtime_channel}")

        result = self._run(command, cwd=self.golfsimras_root, timeout=45)
        self._log("info" if result.ok else "error", result.detail)
        return result

    def stop(self) -> ProxyCommandResult:
        result = self._run(
            [self._command_paths["nmcli"], "connection", "down", "railgolf-runtime-ap"],
            cwd=None,
            timeout=20,
        )
        self._log("info" if result.ok else "error", result.detail)
        return result

    def discovery(self) -> dict:
        if self._last_discovery_response is None:
            return {
                "last_response": None,
                "detail": "No FS Golf discovery packet has been captured or proxied yet.",
            }
        return {
            "last_response": self._last_discovery_response,
            "detail": "Last discovery response observed by the Pi proxy brain.",
        }

    def connections(self) -> list[ProxyConnectionState]:
        return [
            ProxyConnectionState(
                name="client_ap",
                connected=bool(self._wlan_clients()),
                detail=f"{self.client_interface} stations: {', '.join(self._wlan_clients()) or 'none'}",
            ),
            ProxyConnectionState(
                name="mevo_ip",
                connected=self._ping(self.mevo_ip),
                detail=f"{self.mevo_ip} on {self.mevo_interface}",
            ),
            *[
                ProxyConnectionState(
                    name=f"tcp_{port}",
                    connected=self._tcp_connect(self.mevo_ip, port),
                    detail=f"{self.mevo_ip}:{port}",
                )
                for port in self.mevo_ports
            ],
        ]

    def logs(self) -> list[dict]:
        return list(self._logs)

    def _run(
        self,
        command: list[str],
        *,
        cwd: Path | None,
        timeout: int,
    ) -> ProxyCommandResult:
        try:
            completed = subprocess.run(
                command,
                cwd=cwd,
                check=False,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            return ProxyCommandResult(ok=False, detail=str(error))

        detail = "\n".join(
            part.strip() for part in (completed.stdout, completed.stderr) if part.strip()
        )
        return ProxyCommandResult(ok=completed.returncode == 0, detail=detail or "ok")

    def _esp32_status(self) -> str | None:
        try:
            response = httpx.get(f"{self.esp32_control_url}/status", timeout=3.0)
            response.raise_for_status()
            return response.text
        except httpx.HTTPError:
            return None

    def _wlan_clients(self) -> list[str]:
        result = self._run(
            [self._command_paths["iw"], "dev", self.client_interface, "station", "dump"],
            cwd=None,
            timeout=5,
        )
        if not result.ok:
            return []
        clients: list[str] = []
        for line in result.detail.splitlines():
            if line.startswith("Station "):
                clients.append(line.split()[1])
        return clients

    def _can_connect_any_mevo_port(self) -> bool:
        return any(self._tcp_connect(self.mevo_ip, port) for port in self.mevo_ports)

    def _tcp_connect(self, host: str, port: int) -> bool:
        try:
            with socket.create_connection((host, port), timeout=1.0):
                return True
        except OSError:
            return False

    def _ping(self, host: str) -> bool:
        return self._run([self._command_paths["ping"], "-c", "1", "-W", "1", host], cwd=None, timeout=3).ok

    def _forwarded_packet_count(self) -> int:
        result = self._run([self._command_paths["iptables"], "-v", "-S", "FORWARD"], cwd=None, timeout=5)
        if not result.ok:
            return 0
        total = 0
        for line in result.detail.splitlines():
            if self.client_interface in line and self.mevo_interface in line:
                total += self._counter_from_iptables_line(line)
        return total

    def _counter_from_iptables_line(self, line: str) -> int:
        marker = " -c "
        if marker not in line:
            return 0
        try:
            return int(line.split(marker, 1)[1].split()[0])
        except (IndexError, ValueError):
            return 0

    def _parse_ports(self, ports: str) -> list[int]:
        parsed: list[int] = []
        for item in ports.split(","):
            try:
                parsed.append(int(item.strip()))
            except ValueError:
                continue
        return parsed or [5100, 1258]

    def _log(self, level: str, message: str) -> None:
        self._logs.append(
            {
                "captured_at": datetime.now(UTC),
                "level": level,
                "message": message,
            }
        )

    def _find_command(self, name: str, fallback: str) -> str:
        result = subprocess.run(
            ["sh", "-c", f"command -v {name}"],
            check=False,
            capture_output=True,
            text=True,
        )
        command = result.stdout.strip()
        return command or fallback
