import 'dart:ui' show Size;

/// Bounding box pixel dari YOLO di backend (`x, y, width, height` pada
/// gambar yang di-decode OpenCV, origin kiri atas).
class MedicineBoundingBox {
  const MedicineBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory MedicineBoundingBox.fromJson(Map<String, dynamic> json) {
    return MedicineBoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Response `POST /vot/medicine-detect`.
class VotMedicineDetectResult {
  const VotMedicineDetectResult({
    required this.dailyMedicationId,
    required this.medicineScheduleId,
    required this.expectedMedicine,
    required this.detectedMedicine,
    required this.confidence,
    required this.boundingBox,
    required this.medicineMatch,
    required this.status,
    required this.votStep,
    required this.message,
    this.attemptCount = 0,
    this.canRetry = true,
    this.failureReason,
  });

  final int dailyMedicationId;
  final int medicineScheduleId;
  final String expectedMedicine;
  final String? detectedMedicine;
  final double confidence;
  final MedicineBoundingBox? boundingBox;
  final bool medicineMatch;
  final String status;
  final String votStep;
  final String message;
  final int attemptCount;
  final bool canRetry;
  final String? failureReason;

  factory VotMedicineDetectResult.fromJson(Map<String, dynamic> json) {
    final dynamic rawBox = json['bounding_box'];
    MedicineBoundingBox? box;
    if (rawBox is Map) {
      box = MedicineBoundingBox.fromJson(Map<String, dynamic>.from(rawBox));
    }

    final String? detected = json['detected_medicine']?.toString().trim();

    return VotMedicineDetectResult(
      dailyMedicationId: (json['daily_medication_id'] as num?)?.toInt() ?? 0,
      medicineScheduleId:
          (json['medicine_schedule_id'] as num?)?.toInt() ?? 0,
      expectedMedicine: json['expected_medicine']?.toString().trim() ?? '',
      detectedMedicine: (detected == null || detected.isEmpty) ? null : detected,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      boundingBox: box,
      medicineMatch: json['medicine_match'] as bool? ?? false,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      message: json['message']?.toString().trim() ?? '',
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      canRetry: json['can_retry'] as bool? ?? true,
      failureReason: json['failure_reason']?.toString().trim(),
    );
  }
}

/// Ukuran JPEG yang dikirim ke backend, untuk memetakan bounding box ke preview.
class CapturedImageSize {
  const CapturedImageSize(this.width, this.height);

  final int width;
  final int height;

  Size get asSize => Size(width.toDouble(), height.toDouble());
}
