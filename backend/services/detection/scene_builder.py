"""
VisionMate AI - Scene Summary Builder
=======================================
Converts raw detection lists into natural-language scene descriptions.
Supports English, Hindi, and Telugu.
Handles partial detections, low-confidence objects, and traffic signals.
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
        "unidentified": "Unidentified object detected {direction}.",
        "partial_edge": "Partially visible object detected {direction}. Proceed with caution.",
        "traffic_signal": "Traffic signal ahead.",
        "bench_available": "Bench available to sit on {direction}.",
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
        "unidentified": "{direction} अज्ञात वस्तु मिली।",
        "partial_edge": "{direction} आंशिक रूप से दिखने वाली वस्तु है। सावधान रहें।",
        "traffic_signal": "आगे ट्रैफिक सिग्नल है।",
        "bench_available": "{direction} बैठने के लिए बेंच उपलब्ध है।",
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
        "unidentified": "{direction} గుర్తింపులేని వస్తువు కనుగొనబడింది.",
        "partial_edge": "{direction} పాక్షికంగా కనిపించే వస్తువు ఉంది. జాగ్రత్తగా వెళ్ళండి.",
        "traffic_signal": "ముందు ట్రాఫిక్ సిగ్నల్ ఉంది.",
        "bench_available": "{direction} కూర్చోవడానికి బెంచ్ అందుబాటులో ఉంది.",
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
        "traffic light": "ट्रैफिक लाइट", "stop sign": "स्टॉप साइन",
        "horse": "घोड़ा", "cow": "गाय", "bird": "पक्षी",
        "umbrella": "छाता", "book": "किताब", "cup": "कप",
        "knife": "चाकू", "fork": "कांटा", "spoon": "चम्मच",
        "bowl": "कटोरा", "vase": "फूलदान", "scissors": "कैंची",
        "sports ball": "गेंद",
    },
    "te": {
        "person": "వ్యక్తి", "car": "కారు", "bus": "బస్సు", "truck": "ట్రక్కు",
        "motorcycle": "మోటార్‌సైకిల్", "bicycle": "సైకిల్", "chair": "కుర్చీ",
        "bench": "బెంచ్", "dining table": "టేబుల్", "couch": "సోఫా",
        "potted plant": "మొక్క", "bed": "మంచం", "laptop": "లాప్‌టాప్",
        "cell phone": "మొబైల్", "backpack": "బ్యాగ్", "handbag": "హ్యాండ్‌బ్యాగ్",
        "suitcase": "సూట్‌కేస్", "dog": "కుక్క", "cat": "పిల్లి",
        "traffic light": "ట్రాఫిక్ లైట్", "stop sign": "స్టాప్ సైన్",
        "horse": "గుర్రం", "cow": "ఆవు", "bird": "పక్షి",
        "umbrella": "గొడుగు", "book": "పుస్తకం", "cup": "కప్పు",
        "knife": "కత్తి", "fork": "ఫోర్క్", "spoon": "చెంచా",
        "bowl": "గిన్నె", "vase": "పూల కుండీ", "scissors": "కత్తెర",
        "sports ball": "బంతి",
    },
}

# Low confidence threshold — objects below this are reported as "unidentified"
_LOW_CONFIDENCE_THRESHOLD = 0.5


def _translate_label(label: str, lang: str) -> str:
    if lang in _LABEL_TRANSLATIONS:
        return _LABEL_TRANSLATIONS[lang].get(label, label)
    return label


def _t(lang: str) -> dict:
    return _TRANSLATIONS.get(lang, _TRANSLATIONS["en"])


def _is_partial_detection(bbox: list, img_width: int = 640, img_height: int = 480) -> bool:
    """Returns True if the bounding box touches or exceeds image edges."""
    if not bbox or len(bbox) < 4:
        return False
    x1, y1, x2, y2 = bbox
    margin = 5  # pixels from edge considered "touching"
    return (x1 <= margin or y1 <= margin or
            x2 >= img_width - margin or y2 >= img_height - margin)


def _direction_label(direction: str, t: dict) -> str:
    if direction == "left":
        return t["left"]
    elif direction == "right":
        return t["right"]
    else:
        return t["ahead"]


def build_scene_summary(
    detections: list[dict],
    lang: str = "en",
    img_width: int = 640,
    img_height: int = 480,
) -> str:
    t = _t(lang)

    if not detections:
        return t["clear"]

    label_groups: dict[str, list[dict]] = {}
    low_conf_detections: list[dict] = []
    partial_edge_detections: list[dict] = []

    for det in detections:
        conf = det.get("confidence", 1.0)
        bbox = det.get("bbox", [])

        # Low confidence → unidentified
        if conf < _LOW_CONFIDENCE_THRESHOLD:
            low_conf_detections.append(det)
            continue

        # Check if bounding box touches image edges → partial detection
        if _is_partial_detection(bbox, img_width, img_height):
            partial_edge_detections.append(det)
            # Still process normally but we'll add a partial note
            label_groups.setdefault(det["label"], []).append(det)
        else:
            label_groups.setdefault(det["label"], []).append(det)

    sentences = []

    # ── Traffic lights ────────────────────────────────────────────────────────
    if "traffic light" in label_groups:
        tl_items = label_groups.pop("traffic light")
        # Report traffic signal (color detection would require extra CV processing)
        sentences.append(t["traffic_signal"])

    # ── Stop signs ───────────────────────────────────────────────────────────
    if "stop sign" in label_groups:
        stop_items = label_groups.pop("stop sign")
        directions = Counter(s["direction"] for s in stop_items)
        dir_str = _direction_summary(directions, t)
        if lang == "hi":
            sentences.append(f"आगे स्टॉप साइन है {dir_str}.")
        elif lang == "te":
            sentences.append(f"{dir_str} స్టాప్ సైన్ ఉంది.")
        else:
            sentences.append(f"Stop sign {dir_str}.")

    # ── Benches ───────────────────────────────────────────────────────────────
    if "bench" in label_groups:
        bench_items = label_groups.pop("bench")
        for bench in bench_items:
            dir_label = _direction_label(bench["direction"], t)
            sentences.append(t["bench_available"].format(direction=dir_label))

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

    # ── Partial edge detections ───────────────────────────────────────────────
    if partial_edge_detections:
        # Report the first unique direction with a partial note
        seen_dirs = set()
        for det in partial_edge_detections:
            d = det["direction"]
            if d not in seen_dirs:
                seen_dirs.add(d)
                dir_label = _direction_label(d, t)
                sentences.append(t["partial_edge"].format(direction=dir_label))

    # ── Low confidence / unidentified objects ─────────────────────────────────
    if low_conf_detections:
        seen_dirs = set()
        for det in low_conf_detections:
            d = det["direction"]
            if d not in seen_dirs:
                seen_dirs.add(d)
                dir_label = _direction_label(d, t)
                sentences.append(t["unidentified"].format(direction=dir_label))

    # ── Proximity warnings ────────────────────────────────────────────────────
    very_close = [d for d in detections if d["distance_label"] == "very_close"
                  and d.get("confidence", 1.0) >= _LOW_CONFIDENCE_THRESHOLD]
    close = [d for d in detections if d["distance_label"] == "close"
             and d.get("confidence", 1.0) >= _LOW_CONFIDENCE_THRESHOLD]

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

    if not sentences:
        return t["clear"]

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
