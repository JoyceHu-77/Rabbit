from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # 例：sqlite:///./data/rabbit.db 或 postgresql+psycopg2://user:pass@host:5432/rabbit
    database_url: str = "sqlite:///./data/rabbit.db"
    run_seed_on_empty: bool = True


settings = Settings()
