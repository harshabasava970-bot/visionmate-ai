"""
VisionMate AI - /navigation Router
=====================================
Provides step-by-step walking directions with voice instructions.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from services.navigation import get_directions
from services.voice import text_to_speech
from utils.logger import setup_logger

router = APIRouter()
logger = setup_logger(__name__)


class NavigationRequest(BaseModel):
    origin_lat: float = Field(..., description="Current latitude")
    origin_lng: float = Field(..., description="Current longitude")
    destination: str = Field(..., description="Destination address or place name")
    mode: str = Field("walking", description="Travel mode: walking | transit | driving")
    lang: str = Field("en", description="TTS language code")


class NavigationStep(BaseModel):
    instruction: str
    distance: str
    duration: str


class NavigationResponse(BaseModel):
    steps: list[NavigationStep]
    total_distance: str
    total_duration: str
    voice_instructions: list[str]
    first_instruction_audio: str
    start_address: str
    end_address: str


@router.post("/", response_model=NavigationResponse)
async def navigate(req: NavigationRequest):
    """
    Get walking directions and return voice-ready step instructions.
    """
    try:
        result = get_directions(
            req.origin_lat, req.origin_lng, req.destination, req.mode
        )
    except ValueError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:
        logger.error(f"Navigation error: {exc}")
        raise HTTPException(status_code=500, detail="Navigation service unavailable.")

    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])

    # Generate TTS for the first instruction
    first_instruction = (
        result["voice_instructions"][0]
        if result["voice_instructions"]
        else "Navigation started."
    )
    audio_b64 = text_to_speech(first_instruction, lang=req.lang)

    return NavigationResponse(
        steps=[NavigationStep(**s) for s in result["steps"]],
        total_distance=result["total_distance"],
        total_duration=result["total_duration"],
        voice_instructions=result["voice_instructions"],
        first_instruction_audio=audio_b64,
        start_address=result["start_address"],
        end_address=result["end_address"],
    )
