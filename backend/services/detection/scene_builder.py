"""
VisionMate AI - Scene Summary Builder
=======================================
Converts raw detection lists into natural-language scene descriptions
suitable for Text-to-Speech output.
"""

from __future__ import annotations
from collections import Counter


def build_scene_summary(detections: list[dict]) -> str:
    """
    Generate a human-friendly scene description from detections.

    Args:
        detections: Output from ObjectDetector.detect()

    Returns:
        Natural language string, e.g.
        "Three people are ahead of you. A car is on your right. Crowded area detected."
    """
    if not detections:
        return "The path ahead appears clear."

    # Group by label
    label_groups: dict[str, list[dict]] = {}
    for det in detections:
        label_groups.setdefault(det["label"], []).append(det)

    sentences = []

    # ── People ────────────────────────────────────────────────────────────────
    if "person" in label_groups:
        people = label_groups.pop("person")
        count = len(people)
        directions = Counter(p["direction"] for p in people)
        dir_str = _direction_summary(directions)
        noun = "person" if count == 1 else "people"
        sentences.append(f"{_number_word(count)} {noun} {dir_str}.")

        # Crowd warning
        if count >= 5:
            sentences.append("Crowded area ahead. Please proceed carefully.")

    # ── Vehicles ──────────────────────────────────────────────────────────────
    vehicle_labels = {"car", "bus", "truck", "motorcycle", "bicycle"}
    for vlabel in vehicle_labels:
        if vlabel in label_groups:
            vehicles = label_groups.pop(vlabel)
            count = len(vehicles)
            directions = Counter(v["direction"] for v in vehicles)
            dir_str = _direction_summary(directions)
            noun = vlabel if count == 1 else vlabel + "s"
            sentences.append(f"{_number_word(count)} {noun} {dir_str}.")

    # ── Remaining objects ─────────────────────────────────────────────────────
    for label, items in label_groups.items():
        count = len(items)
        directions = Counter(i["direction"] for i in items)
        dir_str = _direction_summary(directions)
        noun = label if count == 1 else label + "s"
        sentences.append(f"{_number_word(count)} {noun} {dir_str}.")

    # ── Proximity warnings ────────────────────────────────────────────────────
    very_close = [d for d in detections if d["distance_label"] == "very_close"]
    close = [d for d in detections if d["distance_label"] == "close"]

    if very_close:
        labels = ", ".join(set(d["label"] for d in very_close))
        sentences.append(f"Warning! {labels} very close. Stop immediately.")
    elif close:
        labels = ", ".join(set(d["label"] for d in close))
        sentences.append(f"Caution. {labels} nearby.")

    return " ".join(sentences)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _direction_summary(directions: Counter) -> str:
    """Convert direction counter to readable phrase."""
    if len(directions) == 1:
        d = list(directions.keys())[0]
        return f"on your {d}" if d in ("left", "right") else "ahead of you"
    parts = []
    for d, _ in directions.most_common():
        parts.append("ahead" if d == "center" else f"on your {d}")
    return " and ".join(parts)


_WORDS = [
    "zero", "one", "two", "three", "four", "five",
    "six", "seven", "eight", "nine", "ten",
]


def _number_word(n: int) -> str:
    """Convert small integer to word, fall back to digit string."""
    if 0 <= n < len(_WORDS):
        return _WORDS[n].capitalize()
    return str(n)
