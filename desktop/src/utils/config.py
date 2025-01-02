from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Desktop Controller"
    BROADCAST_PORT: int = 8081
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000

settings = Settings()
