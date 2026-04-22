from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Rail Golf"
    app_env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    database_url: str = "sqlite:///./rail_golf.db"
    media_root: str = "./media"
    import_root: str = "./imports"
    timezone: str = "America/Los_Angeles"
    enable_mevo_rf: bool = True
    enable_oak: bool = False
    enable_sensors: bool = True
    esp32_control_url: str = "http://192.168.7.2"
    golfsimras_root: str = "/home/zoly55/repos/GolfSimRAS"
    proxy_client_interface: str = "wlan1"
    proxy_mevo_interface: str = "eth1"
    proxy_mevo_ip: str = "192.168.2.1"
    proxy_mevo_ports: str = "5100,1258"
    proxy_log_limit: int = 200

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
