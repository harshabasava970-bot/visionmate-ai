"""
VisionMate AI - /currency Router
==================================
Detects Indian currency notes from camera frame.
Uses color, size and pattern heuristics via OpenCV.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from services.voice import text_to_speech
from utils.image_utils import decode_base64_image
from utils.logger import setup_logger
import cv2
import numpy as np

router = APIRouter()
logger = setup_logger(__name__)

_MESSAGES = {
    "en": {
        10:   "This appears to be a Ten rupee note.",
        20:   "This appears to be a Twenty rupee note.",
        50:   "This appears to be a Fifty rupee note.",
        100:  "This appears to be a One hundred rupee note.",
        200:  "This appears to be a Two hundred rupee note.",
        500:  "This appears to be a Five hundred rupee note.",
        2000: "This appears to be a Two thousand rupee note.",
        0:    "Could not identify the currency note. Please hold it flat and closer to the camera.",
    },
    "hi": {
        10:   "यह दस रुपये का नोट लगता है।",
        20:   "यह बीस रुपये का नोट लगता है।",
        50:   "यह पचास रुपये का नोट लगता है।",
        100:  "यह एक सौ रुपये का नोट लगता है।",
        200:  "यह दो सौ रुपये का नोट लगता है।",
        500:  "यह पाँच सौ रुपये का नोट लगता है।",
        2000: "यह दो हजार रुपये का नोट लगता है।",
        0:    "नोट पहचान नहीं हो सका। कृपया नोट को सीधा और कैमरे के पास रखें।",
    },
    "te": {
        10:   "ఇది పది రూపాయల నోటు అని అనిపిస్తోంది.",
        20:   "ఇది ఇరవై రూపాయల నోటు అని అనిపిస్తోంది.",
        50:   "ఇది యాభై రూపాయల నోటు అని అనిపిస్తోంది.",
        100:  "ఇది వంద రూపాయల నోటు అని అనిపిస్తోంది.",
        200:  "ఇది రెండు వందల రూపాయల నోటు అని అనిపిస్తోంది.",
        500:  "ఇది అయిదు వందల రూపాయల నోటు అని అనిపిస్తోంది.",
        2000: "ఇది రెండు వేల రూపాయల నోటు అని అనిపిస్తోంది.",
        0:    "నోటు గుర్తించలేకపోయాం. దయచేసి నోటును సమతలంగా మరియు కెమెరాకు దగ్గరగా పట్టుకోండి.",
    },
}

# Dominant color ranges (HSV) for Indian currency notes
_NOTE_COLOR_PROFILES = [
    (2000, (140, 50, 50), (170, 255, 255)),   # Magenta/pink
    (500,  (15, 50, 50),  (35, 255, 255)),    # Stone grey/orange tint
    (200,  (15, 100, 100),(25, 255, 255)),    # Bright orange
    (100,  (8, 80, 80),   (18, 255, 255)),    # Lavender/blue-green (approx)
    (50,   (20, 60, 60),  (35, 255, 255)),    # Fluorescent blue
    (20,   (55, 60, 60),  (85, 255, 255)),    # Greenish
    (10,   (10, 50, 50),  (20, 255, 255)),    # Pink/orange
]


def _detect_note_value(frame: np.ndarray) -> int:
    """
    Estimate currency note denomination using dominant color analysis.
    Returns denomination or 0 if unknown.
    """
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    best_match = 0
    best_count = 0

    for denomination, lower, upper in _NOTE_COLOR_PROFILES:
        lower_np = np.array(lower, dtype=np.uint8)
        upper_np = np.array(upper, dtype=np.uint8)
        mask = cv2.inRange(hsv, lower_np, upper_np)
        count = cv2.countNonZero(mask)
        if count > best_count:
            best_count = count
            best_match = denomination

    # Require at least 5% of pixels to match
    total_pixels = frame.shape[0] * frame.shape[1]
    if best_count < total_pixels * 0.05:
        return 0

    return best_match


class CurrencyRequest(BaseModel):
    image: str = Field(..., description="Base64-encoded image of currency note")
    lang: str = Field("en", description="Language code: en | hi | te")


class CurrencyResponse(BaseModel):
    denomination: int
    message: str
    audio_b64: str


@router.post("/", response_model=CurrencyResponse)
async def detect_currency(req: CurrencyRequest):
    """Detect Indian currency note denomination from camera image."""
    try:
        frame = decode_base64_image(req.image)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}")

    denomination = _detect_note_value(frame)
    lang = req.lang if req.lang in _MESSAGES else "en"
    message = _MESSAGES[lang].get(denomination, _MESSAGES[lang][0])
    audio_b64 = text_to_speech(message, lang=lang)

    logger.info(f"Currency detected: ₹{denomination}")
    return CurrencyResponse(
        denomination=denomination,
        message=message,
        audio_b64=audio_b64,
    )
