"""
VisionMate AI - /detect Router
================================
Accepts a base64-encoded camera frame and returns object detections
with bounding boxes, directions, and distance labels.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from services.detection import detector
from services.detection.scene_builder import build_scene_summary
from services.voice import text_to_speech
from utils.image_utils import decode_base64_image, encode_image_base64, draw_detections
from utils.logger import setup_logger

router = APIRouter()
logger = setup_logger(__name__)


class DetectRequest(BaseModel):
    image: str = Field(..., description="Base64-encoded camera frame (JPEG/PNG)")
    lang: str = Field("en", description="Language code for TTS response")
    include_annotated: bool = Field(False, description="Return annotated frame")


class DetectResponse(BaseModel):
    detections: list[dict]
    scene_summary: str
    audio_b64: str
    crowded: bool
    annotated_image: str | None = None


@router.post("/", response_model=DetectResponse)
async def detect_objects(req: DetectRequest):
    """
    Detect objects in a camera frame.

    - Runs YOLOv8 inference
    - Estimates direction (left/center/right) and distance
    - Generates a natural-language scene summary
    - Returns TTS audio for the summary
    """
    try:
        frame = decode_base64_image(req.image)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}")

    detections = detector.detect(frame)
    scene_summary = build_scene_summary(detections)
    crowded = detector.is_crowded(detections)
    audio_b64 = text_to_speech(scene_summary, lang=req.lang)

    annotated = None
    if req.include_annotated:
        annotated_frame = draw_detections(frame.copy(), detections)
        annotated = encode_image_base64(annotated_frame)

    logger.info(f"Detected {len(detections)} objects. Crowded={crowded}")
    return DetectResponse(
        detections=detections,
        scene_summary=scene_summary,
        audio_b64=audio_b64,
        crowded=crowded,
        annotated_image=annotated,
    )
