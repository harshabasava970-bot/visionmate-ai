"""
VisionMate AI - Application Configuration
==========================================
Centralised settings loaded from environment variables / .env file.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False

    # YOLO
    yolo_model_path: str = "models/yolov8n.pt"
    yolo_confidence: float = 0.45
    yolo_iou: float = 0.45

    # Distance thresholds (normalised bounding-box area, 0-1)
    distance_close_threshold: float = 0.15   # ~50 cm
    distance_very_close_threshold: float = 0.35  # ~20 cm

    # Google Maps
    google_maps_api_key: str = ""

    # Emergency / Twilio
    emergency_contact: str = ""
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_from_number: str = ""

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Security
    secret_key: str = "change_me"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Return cached settings instance."""
    return Settings()
