"""
VisionMate AI - Scene Summary Builder
=======================================
Converts raw detection lists into natural-language scene descriptions.
Supports English, Hindi, and Telugu.
Handles partial detections gracefully.
"""

from __future__ import annotations
from collections import Counter

# ── Translations ──────────────────────────────────────────────────────────────

_TRANSLATIONS = {
    "en": {
        "clear": "The path ahead appears clear.",
        "ahead": "ahead of you",
        "left": "on your left",
        "right": "on your right",
        "person": "person", "people": "people",
        "crowded": "Crowded area ahead. Please proceed carefully.",
        "warning": "Warning! {labels} very close. Stop immediately.",
        "caution": "Caution. {labels} nearby.",
        "partial": "Object detected ahead. Could not fully identify it.",
        "numbers": ["zero","one","two","three","four","five","six","seven","eight","nine","ten"],
    },
    "hi": {
        "clear": "आगे का रास्ता साफ है।",
        "ahead": "आपके सामने",
        "left": "आपके बाईं ओर",
        "right": "आपके दाईं ओर",
        "person": "व्यक्ति", "people": "लोग",
        "crowded": "आगे भीड़ है। सावधानी से चलें।",
        "warning": "चेतावनी! {labels} बहुत पास है। तुरंत रुकें।",
        "caution": "सावधान। {labels} पास में है।",
        "partial": "आगे कोई वस्तु है। पूरी तरह पहचान नहीं हो सकी।",
        "numbers": ["शून्य","एक","दो","तीन","चार","पाँच","छह","सात","आठ","नौ","दस"],
    },
    "te": {
        "clear": "ముందు దారి స్పష్టంగా ఉంది.",
        "ahead": "మీ ముందు",
        "left": "మీ ఎడమవైపు",
        "right": "మీ కుడివైపు",
        "person": "వ్యక్తి", "people": "వ్యక్తులు",
        "crowded": "ముందు జనసమూహం ఉంది. జాగ్రత్తగా వెళ్ళండి.",
        "warning": "హెచ్చరిక! {labels} చాలా దగ్గరగా ఉంది. వెంటనే ఆగండి.",
        "caution": "జాగ్రత్త. {labels} దగ్గరలో ఉంది.",
        "partial": "ముందు ఏదో వస్తువు ఉంది. పూర్తిగా గుర్తించలేకపోయాం.",
        "numbers": ["సున్నా","ఒకటి","రెండు","మూడు","నాలుగు","అయిదు","ఆరు","ఏడు","ఎనిమిది","తొమ్మిది","పది"],
    },
}

# Label translations for common objects
_LABEL_TRANSLATIONS = {
    "hi": {
        "person": "व्यक्ति", "car": "कार", "bus": "बस", "truck": "ट्रक",
        "motorcycle": "मोटरसाइकिल", "bicycle": "साइकिल", "chair": "कुर्सी",
        "bench": "बेंच", "dining table": "मेज", "couch": "सोफा",
        "potted plant": "गमला", "bed": "बिस्तर", "laptop": "लैपटॉप",
        "cell phone": "मोबाइल", "backpack": "बैग", "handbag": "हैंडबैग",
        "suitcase": "सूटकेस", "dog": "कुत्ता", "cat": "बिल्ली",
    },
    "te": {
        "person": "వ్యక్తి", "car": "కారు", "bus": "బస్సు", "truck": "ట్రక్కు",
        "motorcycle": "మోటార్‌సైకిల్", "bicycle": "సైకిల్", "chair": "కుర్చీ",
        "bench": "బెంచ్", "dining table": "టేబుల్", "couch": "సోఫా",
        "potted plant": "మొక్క", "bed": "మంచం", "laptop": "లాప్‌టాప్",
        "cell phone": "మొబైల్", "backpack": "బ్యాగ్", "handbag": "హ్యాండ్‌బ్యాగ్",
        "suitcase": "సూట్‌కేస్", "dog": "కుక్క", "cat": "పిల్లి",
    },
}


def _translate_label(label: str, lang: str) -> str:
    if lang in _LABEL_TRANSLATIONS:
        return _LABEL_TRANSLATIONS[lang].get(label, label)
    return label


def _t(lang: str) -> dict:
    return _TRANSLATIONS.get(lang, _TRANSLATIONS["en"])


def build_scene_summary(detections: list[dict], lang: str = "en") -> str:
    t = _t(lang)

    if not detections:
        return t["clear"]

    label_groups: dict[str, list[dict]] = {}
    for det in detections:
        label_groups.setdefault(det["label"], []).append(det)

    sentences = []

    # ── People ────────────────────────────────────────────────────────────────
    if "person" in label_groups:
        people = label_groups.pop("person")
        count = len(people)
        directions = Counter(p["direction"] for p in people)
        dir_str = _direction_summary(directions, t)
        noun = t["person"] if count == 1 else t["people"]
        num = _number_word(count, t)
        sentences.append(f"{num} {noun} {dir_str}.")
        if count >= 5:
            sentences.append(t["crowded"])

    # ── Vehicles ──────────────────────────────────────────────────────────────
    for vlabel in ["car", "bus", "truck", "motorcycle", "bicycle"]:
        if vlabel in label_groups:
            vehicles = label_groups.pop(vlabel)
            count = len(vehicles)
            directions = Counter(v["direction"] for v in vehicles)
            dir_str = _direction_summary(directions, t)
            translated = _translate_label(vlabel, lang)
            num = _number_word(count, t)
            sentences.append(f"{num} {translated} {dir_str}.")

    # ── Other objects ─────────────────────────────────────────────────────────
    for label, items in label_groups.items():
        count = len(items)
        directions = Counter(i["direction"] for i in items)
        dir_str = _direction_summary(directions, t)
        translated = _translate_label(label, lang)
        num = _number_word(count, t)
        sentences.append(f"{num} {translated} {dir_str}.")

    # ── Proximity warnings ────────────────────────────────────────────────────
    very_close = [d for d in detections if d["distance_label"] == "very_close"]
    close = [d for d in detections if d["distance_label"] == "close"]

    if very_close:
        labels = ", ".join(
            set(_translate_label(d["label"], lang) for d in very_close)
        )
        sentences.append(t["warning"].format(labels=labels))
    elif close:
        labels = ", ".join(
            set(_translate_label(d["label"], lang) for d in close)
        )
        sentences.append(t["caution"].format(labels=labels))

    return " ".join(sentences)


def build_partial_detection_message(lang: str = "en") -> str:
    """Used when object is detected but confidence is too low to classify."""
    return _t(lang)["partial"]


def _direction_summary(directions: Counter, t: dict) -> str:
    if len(directions) == 1:
        d = list(directions.keys())[0]
        if d == "left":
            return t["left"]
        elif d == "right":
            return t["right"]
        else:
            return t["ahead"]
    parts = []
    for d, _ in directions.most_common():
        if d == "left":
            parts.append(t["left"])
        elif d == "right":
            parts.append(t["right"])
        else:
            parts.append(t["ahead"])
    return " and ".join(parts)


def _number_word(n: int, t: dict) -> str:
    words = t["numbers"]
    if 0 <= n < len(words):
        return words[n].capitalize() if isinstance(words[n], str) else str(words[n])
    return str(n)
