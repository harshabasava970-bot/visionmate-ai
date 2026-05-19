# VisionMate AI 👁️

> An AI-powered assistant for blind and visually impaired people.  
> Point your phone camera at the world — VisionMate speaks what it sees, warns of obstacles, reads text, detects currency, and calls for help — all hands-free.

---

## 📱 What It Does

| Feature | Description |
|---------|-------------|
| 🎯 Object Detection | Detects people, cars, chairs, trees, obstacles and more using YOLOv8 |
| 🗣️ Continuous Voiceover | Speaks scene every 3 seconds — "Two people ahead. Chair on your left." |
| ⚠️ Collision Alert | Immediate voice warning + vibration when anything is too close |
| 📖 OCR Text Reading | Reads sign boards, bus numbers, medicine labels aloud |
| 💵 Currency Detection | Identifies Indian rupee notes (₹10, ₹20, ₹50, ₹100, ₹200, ₹500, ₹2000) |
| 🎤 Voice Commands | Fully hands-free — say commands in English, Hindi, or Telugu |
| 🧭 Navigation | Voice-guided walking directions — "Can I turn left?" |
| 🆘 Emergency SOS | Say "Activate SOS" or shake phone to send GPS location to emergency contacts |
| 🔋 Battery Alerts | Speaks battery warnings at 30%, 20%, 10% — reminds to connect power bank |
| 🌐 Multilingual | English, हिंदी, తెలుగు — voice commands and responses in your language |

---

## 🎤 Voice Commands

### English
| Say | Action |
|-----|--------|
| "Start scanning" | Begin auto-scan |
| "Stop scanning" | Pause auto-scan |
| "Scan now" | Immediate scan |
| "Read text" | OCR text reading |
| "Which rupee note" | Currency detection |
| "Can I turn left/right" | Check direction safety |
| "Activate SOS" | Emergency alert |
| "What time is it" | Speaks current time |
| "Battery status" | Speaks battery level |

### हिंदी (Hindi)
| बोलें | कार्य |
|-------|-------|
| "स्कैन शुरू करो" | स्कैनिंग शुरू |
| "अभी स्कैन करो" | तुरंत स्कैन |
| "कौन सा नोट है" | नोट पहचान |
| "एसओएस" | आपातकाल |
| "बैटरी कितनी है" | बैटरी स्तर |

### తెలుగు (Telugu)
| చెప్పండి | చర్య |
|----------|------|
| "స్కాన్ ప్రారంభించు" | స్కాన్ మొదలు |
| "ఇప్పుడు స్కాన్ చేయి" | వెంటనే స్కాన్ |
| "ఏ నోటు" | నోటు గుర్తింపు |
| "ఎస్ఓఎస్" | అత్యవసరం |
| "బ్యాటరీ ఎంత ఉంది" | బ్యాటరీ స్థాయి |

---

## 👆 Gestures (No voice needed)

| Gesture | Action |
|---------|--------|
| Single tap | Repeat last spoken result |
| Double tap | Scan immediately |
| Long press | Speak current time |
| Shake phone | Trigger SOS |

---

## 🏗️ Tech Stack

**Frontend (Flutter)**
- Flutter 3.x (Android APK + Web)
- Dart
- `speech_to_text` — voice command recognition
- `flutter_tts` — on-device text-to-speech
- `camera` — live camera feed
- `battery_plus` — battery monitoring
- `sensors_plus` — shake detection for SOS
- `vibration` — haptic collision alerts
- `geolocator` — GPS for navigation and SOS

**Backend (Python FastAPI)**
- YOLOv8 (Ultralytics) — real-time object detection
- Tesseract OCR — text recognition
- gTTS — text to speech (English, Hindi, Telugu)
- OpenCV — image processing + currency detection
- Google Maps API — walking navigation
- Twilio — SMS emergency alerts

---

## 📁 Project Structure

```
visionmate_ai/
├── backend/
│   ├── main.py               # FastAPI entry point
│   ├── config.py             # Settings & env vars
│   ├── requirements.txt      # Python dependencies
│   ├── models/               # YOLOv8 weights
│   ├── routers/
│   │   ├── detect.py         # POST /detect
│   │   ├── ocr.py            # POST /ocr
│   │   ├── currency.py       # POST /currency
│   │   ├── scene.py          # POST /scene-summary
│   │   ├── speech.py         # POST /speech-command
│   │   ├── navigation.py     # POST /navigation
│   │   └── sos.py            # POST /sos
│   └── services/
│       ├── detection/        # YOLOv8 + scene builder (EN/HI/TE)
│       ├── ocr/              # Tesseract OCR
│       ├── voice/            # gTTS + speech recognition
│       └── navigation/       # Google Maps
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart        # Auto-launches camera
│   │   │   ├── camera_detection_screen.dart  # Main screen
│   │   │   ├── home_screen.dart
│   │   │   ├── navigation_screen.dart
│   │   │   ├── settings_screen.dart      # Language selector
│   │   │   └── emergency_contacts_screen.dart
│   │   ├── services/
│   │   │   ├── audio_service.dart        # TTS (web + mobile)
│   │   │   ├── battery_service.dart      # Battery alerts
│   │   │   ├── camera_service.dart
│   │   │   ├── voice_command_service.dart # EN/HI/TE commands
│   │   │   ├── api_service.dart
│   │   │   ├── haptic_service.dart
│   │   │   └── location_service.dart
│   │   └── utils/
│   └── pubspec.yaml
│
└── docs/
    ├── API_DOCUMENTATION.md
    ├── INSTALLATION.md
    ├── DEPLOYMENT.md
    └── TESTING.md
```

---

## 🚀 Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Visit `http://localhost:8000/docs` for interactive API docs.

### Android APK

```bash
cd frontend
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Web (Demo)

```bash
cd frontend
flutter run -d chrome
```

---

## 🌐 Live Demo

| Service | URL |
|---------|-----|
| Web App | [visionmate-ai-phi.vercel.app](https://visionmate-ai-phi.vercel.app) |
| Backend API | [visionmate-ai.onrender.com](https://visionmate-ai.onrender.com) |
| API Docs | [visionmate-ai.onrender.com/docs](https://visionmate-ai.onrender.com/docs) |

---

## 🔧 Environment Variables

Copy `.env.example` to `.env` in the backend folder:

```env
GOOGLE_MAPS_API_KEY=your_key_here
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
EMERGENCY_CONTACT=+91XXXXXXXXXX
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/detect/` | Detect objects (supports lang=en/hi/te) |
| POST | `/ocr/` | Extract text from image |
| POST | `/currency/` | Identify Indian rupee note |
| POST | `/scene-summary/` | Natural language scene description |
| POST | `/speech-command/` | Process voice command |
| POST | `/navigation/` | Walking directions |
| POST | `/sos/` | Emergency alert with GPS |
| GET | `/health` | Health check |

---

## ♿ Accessibility Design

- **Voice-first** — everything controllable by voice, no screen needed
- **Auto-start** — camera opens immediately on launch
- **Continuous scanning** — speaks surroundings every 3 seconds automatically
- **Collision alert** — immediate warning when obstacle is too close
- **Battery alerts** — warns at 30%, 20%, 10% to connect power bank
- **Multilingual** — English, Hindi, Telugu
- **Haptic feedback** — vibration patterns for proximity warnings
- **Shake-to-SOS** — emergency trigger without finding any button
- **High contrast** dark theme, large touch targets

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

Built with ❤️ to make the world more accessible for blind and visually impaired people.
