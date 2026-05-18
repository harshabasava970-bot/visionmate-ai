"""
VisionMate AI - YOLOv8 Object Detector
========================================
Wraps Ultralytics YOLOv8 for real-time object detection.
Provides direction estimation and distance approximation.
"""

from __future__ import annotations

import numpy as np
from config import get_settings
from utils.logger import setup_logger

logger = setup_logger(__name__)
settings = get_settings()

# Try to import ultralytics — gracefully degrade if not installed (e.g. Render free tier)
try:
    from ultralytics import YOLO
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False
    logger.warning("ultralytics not installed — detection will return empty results.")

# ── Classes we care about (subset of COCO 80) ────────────────────────────────
RELEVANT_CLASSES = {
    0:  "person",
    1:  "bicycle",
    2:  "car",
    3:  "motorcycle",
    5:  "bus",
    7:  "truck",
    13: "bench",
    15: "cat",
    16: "dog",
    24: "backpack",
    26: "handbag",
    28: "suitcase",
    56: "chair",
    57: "couch",
    58: "potted plant",
    59: "bed",
    60: "dining table",
    63: "laptop",
    67: "cell phone",
    # Custom additions (if fine-tuned model used)
    # 80: "stairs",
    # 81: "door",
    # 82: "obstacle",
}


class ObjectDetector:
    """Singleton YOLOv8 detector."""

    _instance: "ObjectDetector | None" = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._loaded = False
        return cls._instance

    def load(self):
        """Load the YOLO model (called once at startup)."""
        if self._loaded:
            return
        if not YOLO_AVAILABLE:
            logger.warning("YOLO not available — skipping model load.")
            self._loaded = True
            return
        logger.info(f"Loading YOLO model from {settings.yolo_model_path}")
        self.model = YOLO(settings.yolo_model_path)
        self._loaded = True
        logger.info("YOLO model loaded successfully.")

    # ── Core detection ────────────────────────────────────────────────────────

    def detect(self, frame: np.ndarray) -> list[dict]:
        if not self._loaded:
            self.load()
        if not YOLO_AVAILABLE or not hasattr(self, 'model'):
            return []  # Graceful fallback

        h, w = frame.shape[:2]
        results = self.model(
            frame,
            conf=settings.yolo_confidence,
            iou=settings.yolo_iou,
            verbose=False,
        )[0]

        detections = []
        for box in results.boxes:
            cls_id = int(box.cls[0])
            if cls_id not in RELEVANT_CLASSES:
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
            conf = float(box.conf[0])
            label = RELEVANT_CLASSES[cls_id]

            # Direction: divide frame into thirds
            cx = (x1 + x2) / 2
            if cx < w / 3:
                direction = "left"
            elif cx > 2 * w / 3:
                direction = "right"
            else:
                direction = "center"

            # Distance approximation via bounding-box area ratio
            area_ratio = ((x2 - x1) * (y2 - y1)) / (w * h)
            if area_ratio >= settings.distance_very_close_threshold:
                distance_label = "very_close"
            elif area_ratio >= settings.distance_close_threshold:
                distance_label = "close"
            else:
                distance_label = "far"

            detections.append({
                "label": label,
                "confidence": round(conf, 3),
                "bbox": [x1, y1, x2, y2],
                "direction": direction,
                "distance_label": distance_label,
                "area_ratio": round(area_ratio, 4),
            })

        return detections

    # ── Crowd detection ───────────────────────────────────────────────────────

    def is_crowded(self, detections: list[dict], threshold: int = 5) -> bool:
        """Return True if more than `threshold` persons detected."""
        person_count = sum(1 for d in detections if d["label"] == "person")
        return person_count >= threshold


# Module-level singleton
detector = ObjectDetector()
