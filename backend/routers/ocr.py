"""
VisionMate AI - /ocr Router
=============================
Reads text from an image (sign boards, labels, currency, bus numbers)
and returns the extracted text plus TTS audio.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from services.ocr import read_text_from_frame
from services.voice import text_to_speech
from utils.image_utils import decode_base64_image

router = APIRouter()


class OCRRequest(BaseModel):
    image: str = Field(..., description="Base64-encoded image")
    mode: str = Field("auto", description="OCR engine: auto | tesseract | easyocr")
    languages: list[str] = Field(["en"], description="Language codes for EasyOCR")
    lang: str = Field("en", description="TTS language code")


class OCRResponse(BaseModel):
    text: str
    engine: str
    word_count: int
    audio_b64: str


@router.post("/", response_model=OCRResponse)
async def ocr_read(req: OCRRequest):
    """
    Extract text from an image and return it as speech.

    Supports:
    - Sign boards
    - Bus numbers
    - Medicine labels
    - Currency notes
    """
    try:
        frame = decode_base64_image(req.image)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}")

    result = read_text_from_frame(frame, mode=req.mode, languages=req.languages)

    # Build TTS message
    tts_text = (
        f"Text detected: {result['text']}"
        if result["word_count"] > 0
        else "No text found in the image."
    )
    audio_b64 = text_to_speech(tts_text, lang=req.lang)

    return OCRResponse(
        text=result["text"],
        engine=result["engine"],
        word_count=result["word_count"],
        audio_b64=audio_b64,
    )
