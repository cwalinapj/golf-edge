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

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
