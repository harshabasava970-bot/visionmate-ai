"""
VisionMate AI - Speech Recognition Service
============================================
Transcribes audio using Google Speech Recognition (via SpeechRecognition library).
Lightweight alternative to Whisper — no model download required.
Parses recognised commands into structured intents.
"""

from __future__ import annotations

import io
import tempfile
import os
import speech_recognition as sr
from utils.logger import setup_logger

logger = setup_logger(__name__)

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

# Shared recognizer instance
_recognizer = sr.Recognizer()


def transcribe_audio(audio_bytes: bytes, language: str = "en") -> dict:
    """
    Transcribe raw audio bytes (WAV/MP3/M4A) using Google Speech Recognition.

    Args:
        audio_bytes: Raw audio file bytes.
        language: BCP-47 language code (e.g. "en-US", "hi-IN").

    Returns:
        {
            "transcript": str,
            "intent": str | None,
            "confidence": float
        }
    """
    # Map short codes to BCP-47 format Google expects
    lang_map = {
        "en": "en-US",
        "hi": "hi-IN",
        "es": "es-ES",
        "fr": "fr-FR",
        "de": "de-DE",
        "ar": "ar-SA",
        "zh": "zh-CN",
        "pt": "pt-BR",
        "ru": "ru-RU",
        "ja": "ja-JP",
    }
    bcp47_lang = lang_map.get(language, "en-US")

    # Write to temp WAV file
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    transcript = ""
    try:
        with sr.AudioFile(tmp_path) as source:
            audio_data = _recognizer.record(source)

        transcript = _recognizer.recognize_google(
            audio_data, language=bcp47_lang
        ).strip().lower()
        logger.debug(f"Transcript: '{transcript}'")

    except sr.UnknownValueError:
        logger.warning("Speech not understood.")
        transcript = ""
    except sr.RequestError as exc:
        logger.error(f"Google Speech API error: {exc}")
        transcript = ""
    except Exception as exc:
        logger.error(f"Transcription error: {exc}")
        transcript = ""
    finally:
        os.unlink(tmp_path)

    # Match intent
    intent = None
    for phrase, mapped_intent in INTENT_MAP.items():
        if phrase in transcript:
            intent = mapped_intent
            break

    return {
        "transcript": transcript,
        "intent": intent,
        "confidence": 0.9,
    }
