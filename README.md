# VisionMate AI 👁️

> An AI-powered assistant for blind and visually impaired people.  
> Real-time object detection, voice feedback, OCR text reading, navigation, and emergency SOS — all in one app.

---

## 📱 What It Does

| Feature | Description |
|---------|-------------|
| 🎯 Object Detection | Detects people, cars, obstacles, dogs, chairs and more using YOLOv8 |
| 🗣️ Voice Feedback | Speaks what it sees — "3 people ahead, car on your left" |
| 📏 Distance Estimation | Warns when objects are dangerously close with haptic vibration |
| 📖 OCR Text Reading | Reads sign boards, bus numbers, medicine labels aloud |
| 🎤 Voice Commands | Say "What is ahead?" or "Read text" to trigger actions |
| 🧭 Navigation | Voice-guided walking directions via Google Maps |
| 🆘 Emergency SOS | Double tap to send GPS location to emergency contact |
| 🌐 Web App | Accessible from any browser, no install needed |

---

## 🏗️ Tech Stack

**Frontend**
- Flutter (Mobile + Web)
- Dart
- Provider, SharedPreferences, SpeechToText, FlutterTTS

**Backend**
- Python FastAPI
- YOLOv8 (Ultralytics) — object detection
- EasyOCR + Tesseract — text recognition
- gTTS — text to speech
- OpenCV — image processing
- Google Maps API — navigation

---

## 📁 Project Structure

```
visionmate_ai/
├── backend/                  # FastAPI Python backend
│   ├── main.py               # App entry point
│   ├── config.py             # Settings & env vars
│   ├── requirements.txt      # Python dependencies
│   ├── models/               # YOLO model weights
│   ├── routers/              # API route handlers
│   │   ├── detect.py         # POST /detect
│   │   ├── ocr.py            # POST /ocr
│   │   ├── scene.py          # POST /scene-summary
│   │   ├── speech.py         # POST /speech-command
│   │   ├── navigation.py     # POST /navigation
│   │   └── sos.py            # POST /sos
│   └── services/             # Business logic
│       ├── detection/        # YOLOv8 detector
│       ├── ocr/              # OCR service
│       ├── voice/            # TTS service
│       └── navigation/       # Maps service
│
├── frontend/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── screens/          # UI screens
│   │   ├── services/         # API, camera, audio
│   │   ├── widgets/          # Reusable components
│   │   └── utils/            # Theme, constants
│   └── pubspec.yaml          # Flutter dependencies
│
└── docs/                     # Documentation
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

Visit `http://localhost:8000/docs` to see all API endpoints.

### Frontend (Web)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Frontend (Android)

```bash
flutter run -d <your-device-id>
```

---

## 🌐 Live Demo

| Service | URL |
|---------|-----|
| Web App | [visionmate-ai.vercel.app](https://visionmate-ai.vercel.app) |
| Backend API | [visionmate-api.onrender.com](https://visionmate-api.onrender.com) |
| API Docs | [visionmate-api.onrender.com/docs](https://visionmate-api.onrender.com/docs) |

---

## 🔧 Environment Variables

Copy `.env.example` to `.env` in the backend folder and fill in your keys:

```env
GOOGLE_MAPS_API_KEY=your_key_here
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
EMERGENCY_CONTACT=+1234567890
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/detect/` | Detect objects in image |
| POST | `/ocr/` | Extract text from image |
| POST | `/scene-summary/` | Get natural language scene description |
| POST | `/speech-command/` | Process voice command |
| POST | `/navigation/` | Get walking directions |
| POST | `/sos/` | Trigger emergency alert |
| GET | `/health` | Health check |
| GET | `/docs` | Interactive API docs |

---

## 📱 Screens

- **Splash Screen** — animated loading screen
- **Home Screen** — 4 large accessible buttons
- **Camera Detection** — live object detection with voice
- **Navigation** — voice-guided directions
- **Settings** — API URL, language, voice speed
- **Emergency Contacts** — SOS management

---

## ♿ Accessibility

- High contrast dark theme
- Large touch targets (min 48×48dp)
- Full screen reader support
- Voice-first interaction
- Haptic feedback patterns
- No small text anywhere

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m "Add your feature"`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

Built with ❤️ to make the world more accessible.
