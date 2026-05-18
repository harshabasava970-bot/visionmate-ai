"""
VisionMate AI - Text-to-Speech Service
========================================
Converts text to audio using gTTS and returns base64-encoded MP3.
Supports multiple languages.
"""

from __future__ import annotations

import base64
import io
from gtts import gTTS
from utils.logger import setup_logger

logger = setup_logger(__name__)

# Supported language codes (ISO 639-1)
SUPPORTED_LANGUAGES = {
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "ar": "Arabic",
    "hi": "Hindi",
    "zh": "Chinese",
    "pt": "Portuguese",
    "ru": "Russian",
    "ja": "Japanese",
}


def text_to_speech(text: str, lang: str = "en") -> str:
    """
    Convert text to speech and return base64-encoded MP3 audio.

    Args:
        text: The text to speak.
        lang: BCP-47 language code (default: "en").

    Returns:
        Base64-encoded MP3 string.
    """
    if lang not in SUPPORTED_LANGUAGES:
        logger.warning(f"Unsupported language '{lang}', falling back to 'en'.")
        lang = "en"

    try:
        tts = gTTS(text=text, lang=lang, slow=False)
        buffer = io.BytesIO()
        tts.write_to_fp(buffer)
        buffer.seek(0)
        audio_b64 = base64.b64encode(buffer.read()).decode("utf-8")
        logger.debug(f"TTS generated for text: '{text[:60]}...' [{lang}]")
        return audio_b64
    except Exception as exc:
        logger.error(f"TTS error: {exc}")
        raise
