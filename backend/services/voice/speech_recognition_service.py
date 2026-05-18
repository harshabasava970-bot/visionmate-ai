"""
VisionMate AI - Speech Recognition Service
============================================
Transcribes audio using OpenAI Whisper.
Parses recognised commands into structured intents.
"""

from __future__ import annotations

import io
import tempfile
import os
import whisper
from utils.logger import setup_logger

logger = setup_logger(__name__)

# Load Whisper model once (tiny = fastest, base = balanced)
_whisper_model: whisper.Whisper | None = None


def _get_model() -> whisper.Whisper:
    global _whisper_model
    if _whisper_model is None:
        logger.info("Loading Whisper model (base)…")
        _whisper_model = whisper.load_model("base")
        logger.info("Whisper model loaded.")
    return _whisper_model


# ── Intent mapping ────────────────────────────────────────────────────────────
INTENT_MAP = {
    "what is ahead":    "detect_ahead",
    "what's ahead":     "detect_ahead",
    "read text":        "ocr_read",
    "read the text":    "ocr_read",
    "who is near me":   "detect_people",
    "who's near me":    "detect_people",
    "start navigation": "navigation_start",
    "navigate to":      "navigation_start",
    "stop":             "stop",
    "help":             "sos",
    "emergency":        "sos",
    "call for help":    "sos",
}


def transcribe_audio(audio_bytes: bytes, language: str = "en") -> dict:
    """
    Transcribe raw audio bytes (WAV/MP3/M4A) using Whisper.

    Args:
        audio_bytes: Raw audio file bytes.
        language: Language hint for Whisper (e.g. "en", "es").

    Returns:
        {
            "transcript": str,
            "intent": str | None,
            "confidence": float
        }
    """
    model = _get_model()

    # Write to temp file (Whisper requires a file path)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        result = model.transcribe(tmp_path, language=language, fp16=False)
        transcript = result["text"].strip().lower()
        logger.debug(f"Whisper transcript: '{transcript}'")

        # Match intent
        intent = None
        for phrase, mapped_intent in INTENT_MAP.items():
            if phrase in transcript:
                intent = mapped_intent
                break

        return {
            "transcript": transcript,
            "intent": intent,
            "confidence": 0.95,  # Whisper doesn't expose per-word confidence easily
        }
    finally:
        os.unlink(tmp_path)
