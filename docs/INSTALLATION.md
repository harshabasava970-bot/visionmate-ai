# VisionMate AI — Installation Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Python | 3.10+ | https://python.org |
| Flutter | 3.19+ | https://flutter.dev |
| Android Studio | Latest | https://developer.android.com/studio |
| Tesseract OCR | 5.x | See below |
| Git | Any | https://git-scm.com |

---

## Step 1 — Clone the Project

```bash
git clone https://github.com/yourname/visionmate_ai.git
cd visionmate_ai
```

---

## Step 2 — Backend Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt
```

### Install Tesseract OCR

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr tesseract-ocr-eng
```

**macOS:**
```bash
brew install tesseract
```

**Windows:**
1. Download installer: https://github.com/UB-Mannheim/tesseract/wiki
2. Install to `C:\Program Files\Tesseract-OCR\`
3. Add to PATH: `C:\Program Files\Tesseract-OCR`

### Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `GOOGLE_MAPS_API_KEY` — from Google Cloud Console
- `TWILIO_*` — from Twilio Console (for SOS SMS)
- `EMERGENCY_CONTACT` — phone number in E.164 format

### Download YOLO Model

```bash
# This downloads yolov8n.pt automatically on first run
# Or pre-download:
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"
```

### Create Required Directories

```bash
mkdir logs
```

### Start Backend

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Visit http://localhost:8000/docs to verify.

---

## Step 3 — Frontend Setup

```bash
cd ../frontend

# Install Flutter packages
flutter pub get

# Verify Flutter setup
flutter doctor
```

### Configure API URL

Edit `lib/utils/constants.dart`:
```dart
static const String defaultApiUrl = 'http://YOUR_COMPUTER_IP:8000';
```

For Android emulator, use `http://10.0.2.2:8000`.
For physical device, use your computer's local IP (e.g., `http://192.168.1.100:8000`).

### Add Google Maps API Key

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

### Run the App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

---

## Step 4 — Verify Everything Works

1. Open the app → Splash screen should announce "Welcome to VisionMate AI"
2. Tap "Detect Objects" → Camera should open
3. Point at any object → Detection boxes should appear
4. Voice feedback should play automatically
5. Tap "Read Text" → Point at text → OCR should read it aloud

---

## Troubleshooting

**Camera not working:**
- Check `CAMERA` permission in Android settings
- Ensure no other app is using the camera

**No voice output:**
- Check device volume
- Verify backend is running and reachable
- Check API URL in Settings

**YOLO model not loading:**
- Ensure `yolov8n.pt` is in the `backend/` directory
- Check `YOLO_MODEL_PATH` in `.env`

**Tesseract not found:**
- Verify Tesseract is installed: `tesseract --version`
- On Windows, ensure it's in PATH

**Navigation not working:**
- Verify `GOOGLE_MAPS_API_KEY` is set
- Enable "Directions API" in Google Cloud Console
- Check GPS is enabled on device
