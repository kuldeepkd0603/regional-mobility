from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT_DIR = Path(__file__).resolve().parents[3]


jwt_secret_key: str
jwt_algorithm: str = "HS256"
#access_token_expire_minutes: int = 60
class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str
    access_token_expire_minutes: int = 60
    platform_commission_percent: float = 5
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"    
    model_config = SettingsConfigDict(
        env_file=ROOT_DIR / ".env",
        extra="ignore"
    )


settings = Settings()


