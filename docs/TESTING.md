# VisionMate AI — Testing Strategy

## Backend Tests

### Setup

```bash
cd visionmate_ai/backend
pip install pytest pytest-asyncio httpx
```

### Run Tests

```bash
pytest tests/ -v
```

### Test File: `tests/test_detect.py`

```python
import pytest
from httpx import AsyncClient
from main import app
import base64
from PIL import Image
import io

def make_test_image_b64():
    """Create a small blank test image."""
    img = Image.new("RGB", (640, 480), color=(100, 100, 100))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return base64.b64encode(buf.getvalue()).decode()

@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_detect_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await client.post("/detect/", json={
            "image": make_test_image_b64(),
            "lang": "en",
            "include_annotated": False,
        })
    assert r.status_code == 200
    data = r.json()
    assert "detections" in data
    assert "scene_summary" in data
    assert "audio_b64" in data

@pytest.mark.asyncio
async def test_ocr_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await client.post("/ocr/", json={
            "image": make_test_image_b64(),
            "mode": "tesseract",
            "languages": ["en"],
            "lang": "en",
        })
    assert r.status_code == 200
    assert "text" in r.json()

@pytest.mark.asyncio
async def test_scene_summary():
    detections = [
        {"label": "person", "confidence": 0.9, "bbox": [0,0,100,200],
         "direction": "center", "distance_label": "far", "area_ratio": 0.05}
    ]
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await client.post("/scene-summary/", json={
            "detections": detections,
            "lang": "en",
        })
    assert r.status_code == 200
    assert "person" in r.json()["summary"].lower()

@pytest.mark.asyncio
async def test_sos_no_contact():
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await client.post("/sos/", json={
            "latitude": 51.5074,
            "longitude": -0.1278,
            "lang": "en",
        })
    # Should fail gracefully if no contact configured
    assert r.status_code in (200, 503)
```

---

## Flutter Tests

### Unit Tests

```dart
// test/models/detection_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:visionmate_ai/models/detection_result.dart';

void main() {
  test('DetectionResult parses JSON correctly', () {
    final json = {
      'label': 'person',
      'confidence': 0.92,
      'bbox': [10, 20, 100, 200],
      'direction': 'center',
      'distance_label': 'close',
      'area_ratio': 0.15,
    };
    final det = DetectionResult.fromJson(json);
    expect(det.label, 'person');
    expect(det.isClose, true);
    expect(det.isVeryClose, false);
    expect(det.direction, 'center');
  });
}
```

### Widget Tests

```dart
// test/widgets/large_action_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionmate_ai/widgets/large_action_button.dart';

void main() {
  testWidgets('LargeActionButton renders and responds to tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LargeActionButton(
          icon: Icons.camera,
          label: 'Test',
          color: Colors.blue,
          semanticLabel: 'Test button',
          onTap: () => tapped = true,
        ),
      ),
    ));
    expect(find.text('Test'), findsOneWidget);
    await tester.tap(find.byType(GestureDetector));
    expect(tapped, true);
  });
}
```

### Run Flutter Tests

```bash
cd visionmate_ai/frontend
flutter test
```

---

## Integration Testing

### Manual Test Checklist

- [ ] Camera opens and shows live preview
- [ ] Object detection runs every 500ms
- [ ] Bounding boxes appear on detected objects
- [ ] Voice feedback plays after each detection
- [ ] Green/orange/red boxes indicate distance correctly
- [ ] Vibration triggers for close/very_close objects
- [ ] OCR mode reads text from signs
- [ ] Voice command "what is ahead" triggers detection
- [ ] Navigation provides step-by-step instructions
- [ ] SOS double-tap sends location SMS
- [ ] Shake gesture triggers SOS
- [ ] Settings save and persist across app restarts
- [ ] Offline mode falls back to local TTS
- [ ] App works in dark mode (default)
- [ ] All buttons meet 48×48dp minimum touch target

---

## Performance Benchmarks

| Metric | Target | Measurement |
|--------|--------|-------------|
| Frame processing time | < 500ms | Measure with Dart DevTools |
| API response time | < 2s | FastAPI `/docs` timing |
| TTS latency | < 1s | Audio playback start time |
| App startup time | < 3s | Flutter performance overlay |
| Memory usage | < 200MB | Android Profiler |
