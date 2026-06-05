from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class AppSettings(BaseSettings):
    # Pydantic automatically maps this to an environment variable named CLOUD_PROVIDER_API_KEY
    # If absent, it defaults to None—preventing plaintext credentials from leaking into source control
    CLOUD_PROVIDER_API_KEY: Optional[str] = None

    # Permits reading from a local, uncommitted .env file during local development
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = AppSettings()