# VisionMate AI — Deployment Guide

## Local Development

### Backend

```bash
cd visionmate_ai/backend

# 1. Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Install Tesseract OCR (system dependency)
# Ubuntu/Debian:
sudo apt-get install tesseract-ocr
# macOS:
brew install tesseract
# Windows: download installer from https://github.com/UB-Mannheim/tesseract/wiki

# 4. Download YOLO model
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

# 5. Copy and configure environment
cp .env.example .env
# Edit .env with your API keys

# 6. Create logs directory
mkdir logs

# 7. Start the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend

```bash
cd visionmate_ai/frontend

# 1. Install Flutter (https://flutter.dev/docs/get-started/install)
# 2. Install dependencies
flutter pub get

# 3. Update API URL in Settings screen or constants.dart
# Default: http://10.0.2.2:8000 (Android emulator → host machine)

# 4. Run on device/emulator
flutter run

# 5. Build release APK
flutter build apk --release
```

---

## Docker Deployment (Backend)

```dockerfile
# Dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN mkdir -p logs models

# Pre-download YOLO model
RUN python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
# Build and run
docker build -t visionmate-backend .
docker run -p 8000:8000 --env-file .env visionmate-backend
```

---

## Production Deployment

### Backend on AWS EC2 / DigitalOcean

```bash
# Install nginx
sudo apt install nginx

# Configure nginx reverse proxy
sudo nano /etc/nginx/sites-available/visionmate

# nginx config:
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 10M;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/visionmate /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# SSL with Let's Encrypt
sudo certbot --nginx -d your-domain.com

# Run with gunicorn for production
pip install gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Flutter App Distribution

```bash
# Android APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `YOLO_MODEL_PATH` | No | Path to YOLO weights (default: yolov8n.pt) |
| `YOLO_CONFIDENCE` | No | Detection confidence threshold (default: 0.45) |
| `GOOGLE_MAPS_API_KEY` | Yes (navigation) | Google Maps Directions API key |
| `TWILIO_ACCOUNT_SID` | Yes (SOS SMS) | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | Yes (SOS SMS) | Twilio auth token |
| `TWILIO_FROM_NUMBER` | Yes (SOS SMS) | Twilio phone number |
| `EMERGENCY_CONTACT` | Yes (SOS) | Default emergency phone number |

---

## Performance Tuning

- Use `yolov8n.pt` (nano) for fastest inference on CPU
- Use `yolov8s.pt` (small) for better accuracy with GPU
- Set `YOLO_CONFIDENCE=0.5` to reduce false positives
- Increase `frameIntervalMs` in Flutter constants to reduce API calls
- Enable Redis caching for repeated scene summaries
