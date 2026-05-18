"""
VisionMate AI - OCR Service
=============================
Reads text from images using Tesseract + EasyOCR fallback.
Handles sign boards, bus numbers, medicine labels, currency notes.
"""

from __future__ import annotations

import cv2
import numpy as np
import pytesseract
import easyocr
from utils.logger import setup_logger

logger = setup_logger(__name__)

# EasyOCR reader (loaded lazily)
_easy_reader: easyocr.Reader | None = None


def _get_easy_reader(languages: list[str] = ["en"]) -> easyocr.Reader:
    global _easy_reader
    if _easy_reader is None:
        logger.info("Loading EasyOCR reader…")
        _easy_reader = easyocr.Reader(languages, gpu=False)
        logger.info("EasyOCR ready.")
    return _easy_reader


def preprocess_for_ocr(frame: np.ndarray) -> np.ndarray:
    """
    Enhance image for better OCR accuracy:
    - Convert to grayscale
    - Apply adaptive thresholding
    - Denoise
    """
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    denoised = cv2.fastNlMeansDenoising(gray, h=10)
    thresh = cv2.adaptiveThreshold(
        denoised, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, 11, 2,
    )
    return thresh


def extract_text_tesseract(frame: np.ndarray) -> str:
    """Extract text using Tesseract OCR."""
    processed = preprocess_for_ocr(frame)
    config = "--oem 3 --psm 6"  # Assume uniform block of text
    text = pytesseract.image_to_string(processed, config=config)
    return text.strip()


def extract_text_easyocr(frame: np.ndarray, languages: list[str] = ["en"]) -> str:
    """Extract text using EasyOCR (better for scene text / signs)."""
    reader = _get_easy_reader(languages)
    results = reader.readtext(frame)
    # Concatenate all detected text segments
    texts = [res[1] for res in results if res[2] > 0.4]  # confidence > 40%
    return " ".join(texts).strip()


def read_text_from_frame(
    frame: np.ndarray,
    mode: str = "auto",
    languages: list[str] = ["en"],
) -> dict:
    """
    Main OCR entry point. Tries EasyOCR first, falls back to Tesseract.

    Args:
        frame: BGR numpy array.
        mode: "auto" | "tesseract" | "easyocr"
        languages: List of language codes for EasyOCR.

    Returns:
        {
            "text": str,
            "engine": str,
            "word_count": int
        }
    """
    text = ""
    engine = "none"

    if mode in ("auto", "easyocr"):
        try:
            text = extract_text_easyocr(frame, languages)
            engine = "easyocr"
        except Exception as exc:
            logger.warning(f"EasyOCR failed: {exc}. Falling back to Tesseract.")

    if not text and mode in ("auto", "tesseract"):
        try:
            text = extract_text_tesseract(frame)
            engine = "tesseract"
        except Exception as exc:
            logger.error(f"Tesseract failed: {exc}")

    if not text:
        text = "No readable text found in the image."

    return {
        "text": text,
        "engine": engine,
        "word_count": len(text.split()),
    }
