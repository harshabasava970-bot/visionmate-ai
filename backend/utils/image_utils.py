"""
VisionMate AI - Image Utility Helpers
======================================
Functions for decoding, resizing, and annotating frames.
"""

import base64
import io
import cv2
import numpy as np
from PIL import Image


def decode_base64_image(b64_string: str) -> np.ndarray:
    """
    Decode a base64-encoded image string into an OpenCV BGR numpy array.

    Args:
        b64_string: Base64 encoded image (with or without data URI prefix).

    Returns:
        BGR numpy array.
    """
    # Strip data URI prefix if present
    if "," in b64_string:
        b64_string = b64_string.split(",", 1)[1]

    img_bytes = base64.b64decode(b64_string)
    pil_img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)


def encode_image_base64(frame: np.ndarray) -> str:
    """
    Encode an OpenCV BGR frame to a base64 JPEG string.

    Args:
        frame: BGR numpy array.

    Returns:
        Base64 encoded JPEG string.
    """
    _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
    return base64.b64encode(buffer).decode("utf-8")


def resize_frame(frame: np.ndarray, max_dim: int = 640) -> np.ndarray:
    """
    Resize frame so the longest side equals max_dim, preserving aspect ratio.
    """
    h, w = frame.shape[:2]
    scale = max_dim / max(h, w)
    if scale < 1.0:
        new_w, new_h = int(w * scale), int(h * scale)
        frame = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_AREA)
    return frame


def draw_detections(frame: np.ndarray, detections: list) -> np.ndarray:
    """
    Draw bounding boxes and labels on a frame.

    Args:
        frame: BGR numpy array.
        detections: List of detection dicts with keys:
                    label, confidence, bbox (x1,y1,x2,y2), direction, distance_label.

    Returns:
        Annotated BGR frame.
    """
    for det in detections:
        x1, y1, x2, y2 = det["bbox"]
        label = det.get("label", "object")
        conf = det.get("confidence", 0.0)
        direction = det.get("direction", "center")
        dist_label = det.get("distance_label", "")

        # Choose colour based on distance
        color = (0, 255, 0)  # green = safe
        if dist_label == "very_close":
            color = (0, 0, 255)   # red
        elif dist_label == "close":
            color = (0, 165, 255) # orange

        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        text = f"{label} {conf:.0%} [{direction}]"
        cv2.putText(
            frame, text, (x1, max(y1 - 8, 0)),
            cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2, cv2.LINE_AA,
        )
    return frame
