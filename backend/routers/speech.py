"""
VisionMate AI - /speech-command Router
========================================
Accepts audio bytes, transcribes with Whisper, maps to an intent,
and returns the intent + TTS confirmation.
"""

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from pydantic import BaseModel
from services.voice import transcribe_audio, text_to_speech
from utils.logger import setup_logger

router = APIRouter()
logger = setup_logger(__name__)

# Intent → human-readable confirmation messages
INTENT_RESPONSES = {
    "detect_ahead":      "Scanning what is ahead of you.",
    "ocr_read":          "Reading text in the image.",
    "detect_people":     "Looking for people near you.",
    "navigation_start":  "Starting navigation.",
    "stop":              "Stopping current action.",
    "sos":               "Sending emergency alert.",
    None:                "Sorry, I did not understand that command.",
}


class SpeechResponse(BaseModel):
    transcript: str
    intent: str | None
    confirmation: str
    audio_b64: str


@router.post("/", response_model=SpeechResponse)
async def speech_command(
    audio: UploadFile = File(..., description="Audio file (WAV/MP3/M4A)"),
    language: str = Form("en", description="Language hint for Whisper"),
    lang: str = Form("en", description="TTS language code"),
):
    """
    Process a voice command:
    1. Transcribe audio with Whisper
    2. Map transcript to an intent
    3. Return intent + TTS confirmation audio
    """
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file.")

    result = transcribe_audio(audio_bytes, language=language)
    intent = result["intent"]
    transcript = result["transcript"]

    confirmation = INTENT_RESPONSES.get(intent, INTENT_RESPONSES[None])
    audio_b64 = text_to_speech(confirmation, lang=lang)

    logger.info(f"Voice command: '{transcript}' → intent: {intent}")
    return SpeechResponse(
        transcript=transcript,
        intent=intent,
        confirmation=confirmation,
        audio_b64=audio_b64,
    )
