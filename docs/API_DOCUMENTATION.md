# VisionMate AI — API Documentation

Base URL: `http://<server>:8000`

Interactive docs: `http://<server>:8000/docs` (Swagger UI)

---

## Authentication

Currently open (no auth). Add JWT middleware for production.

---

## Endpoints

### `GET /`
Health check.

**Response**
```json
{ "status": "ok", "service": "VisionMate AI", "version": "1.0.0" }
```

---

### `POST /detect/`
Detect objects in a camera frame.

**Request Body**
```json
{
  "image": "<base64 JPEG string>",
  "lang": "en",
  "include_annotated": false
}
```

**Response**
```json
{
  "detections": [
    {
      "label": "person",
      "confidence": 0.92,
      "bbox": [120, 80, 300, 450],
      "direction": "center",
      "distance_label": "close",
      "area_ratio": 0.18
    }
  ],
  "scene_summary": "Two people ahead of you. Caution. Person nearby.",
  "audio_b64": "<base64 MP3>",
  "crowded": false,
  "annotated_image": null
}
```

**distance_label values**
| Value | Meaning |
|-------|---------|
| `far` | > 50 cm (safe) |
| `close` | ~50 cm (short vibration) |
| `very_close` | ~20 cm (strong vibration + warning) |

---

### `POST /scene-summary/`
Generate scene summary from pre-computed detections.

**Request Body**
```json
{
  "detections": [ /* array of detection dicts */ ],
  "lang": "en"
}
```

**Response**
```json
{
  "summary": "Three people are ahead of you.",
  "audio_b64": "<base64 MP3>"
}
```

---

### `POST /ocr/`
Extract text from an image.

**Request Body**
```json
{
  "image": "<base64 JPEG>",
  "mode": "auto",
  "languages": ["en"],
  "lang": "en"
}
```

**mode values**: `auto` | `tesseract` | `easyocr`

**Response**
```json
{
  "text": "BUS 42 — City Centre",
  "engine": "easyocr",
  "word_count": 4,
  "audio_b64": "<base64 MP3>"
}
```

---

### `POST /speech-command/`
Transcribe a voice command and return intent.

**Request**: `multipart/form-data`
- `audio`: audio file (WAV/MP3/M4A)
- `language`: language hint (default: `en`)
- `lang`: TTS language (default: `en`)

**Response**
```json
{
  "transcript": "what is ahead",
  "intent": "detect_ahead",
  "confirmation": "Scanning what is ahead of you.",
  "audio_b64": "<base64 MP3>"
}
```

**Supported intents**
| Phrase | Intent |
|--------|--------|
| "what is ahead" | `detect_ahead` |
| "read text" | `ocr_read` |
| "who is near me" | `detect_people` |
| "start navigation" | `navigation_start` |
| "stop" | `stop` |
| "emergency" / "help" | `sos` |

---

### `POST /navigation/`
Get walking directions with voice instructions.

**Request Body**
```json
{
  "origin_lat": 51.5074,
  "origin_lng": -0.1278,
  "destination": "Trafalgar Square, London",
  "mode": "walking",
  "lang": "en"
}
```

**Response**
```json
{
  "steps": [
    { "instruction": "Head north on Whitehall", "distance": "200 m", "duration": "3 mins" }
  ],
  "total_distance": "1.2 km",
  "total_duration": "15 mins",
  "voice_instructions": ["Head north on Whitehall. In 200 m."],
  "first_instruction_audio": "<base64 MP3>",
  "start_address": "Current Location",
  "end_address": "Trafalgar Square, London"
}
```

---

### `POST /sos/`
Trigger emergency SOS alert.

**Request Body**
```json
{
  "latitude": 51.5074,
  "longitude": -0.1278,
  "contact_number": "+1234567890",
  "lang": "en"
}
```

**Response**
```json
{
  "status": "triggered",
  "message": "Emergency alert sent. Help is on the way. Stay calm.",
  "audio_b64": "<base64 MP3>",
  "sms_sent": true
}
```

---

## Error Responses

All errors follow standard HTTP status codes:

```json
{ "detail": "Error description here" }
```

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid image, missing fields) |
| 404 | Resource not found (no route found) |
| 500 | Internal server error |
| 503 | Service unavailable (API key not configured) |
