/// VisionMate AI - Detection Result Model

class BoundingBox {
  final int x1, y1, x2, y2;
  const BoundingBox(this.x1, this.y1, this.x2, this.y2);

  factory BoundingBox.fromList(List<dynamic> list) =>
      BoundingBox(list[0] as int, list[1] as int, list[2] as int, list[3] as int);
}

class DetectionResult {
  final String label;
  final double confidence;
  final BoundingBox bbox;
  final String direction;       // left | center | right
  final String distanceLabel;   // far | close | very_close
  final double areaRatio;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.bbox,
    required this.direction,
    required this.distanceLabel,
    required this.areaRatio,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) => DetectionResult(
    label:         json['label'] as String,
    confidence:    (json['confidence'] as num).toDouble(),
    bbox:          BoundingBox.fromList(json['bbox'] as List),
    direction:     json['direction'] as String,
    distanceLabel: json['distance_label'] as String,
    areaRatio:     (json['area_ratio'] as num).toDouble(),
  );

  bool get isVeryClose => distanceLabel == 'very_close';
  bool get isClose     => distanceLabel == 'close';
}

class DetectApiResponse {
  final List<DetectionResult> detections;
  final String sceneSummary;
  final String audioB64;
  final bool crowded;
  final String? annotatedImage;

  const DetectApiResponse({
    required this.detections,
    required this.sceneSummary,
    required this.audioB64,
    required this.crowded,
    this.annotatedImage,
  });

  factory DetectApiResponse.fromJson(Map<String, dynamic> json) => DetectApiResponse(
    detections:    (json['detections'] as List)
        .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    sceneSummary:  json['scene_summary'] as String,
    audioB64:      json['audio_b64'] as String,
    crowded:       json['crowded'] as bool,
    annotatedImage: json['annotated_image'] as String?,
  );
}
