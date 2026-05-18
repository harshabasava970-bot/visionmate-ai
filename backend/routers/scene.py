"""
VisionMate AI - /scene-summary Router
=======================================
Accepts a list of raw detections and returns an intelligent scene summary.
Useful when the client runs on-device YOLO and only sends detection results.
"""

from fastapi import APIRouter
from pydantic import BaseModel, Field
from services.detection.scene_builder import build_scene_summary
from services.voice import text_to_speech

router = APIRouter()


class SceneRequest(BaseModel):
    detections: list[dict] = Field(..., description="List of detection dicts from YOLO")
    lang: str = Field("en", description="Language code for TTS")


class SceneResponse(BaseModel):
    summary: str
    audio_b64: str


@router.post("/", response_model=SceneResponse)
async def scene_summary(req: SceneRequest):
    """
    Generate a natural-language scene summary from pre-computed detections
    and return TTS audio.
    """
    summary = build_scene_summary(req.detections)
    audio_b64 = text_to_speech(summary, lang=req.lang)
    return SceneResponse(summary=summary, audio_b64=audio_b64)
