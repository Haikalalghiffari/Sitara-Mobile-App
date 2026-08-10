import '../models/verification_state.dart';
import 'verification_service.dart';

/// Implementasi sementara tanpa AI.
///
/// Hanya menjalankan urutan state dengan jeda waktu supaya alur UI dapat
/// diuji. Tidak ada deteksi wajah, obat, maupun pose yang benar-benar
/// dilakukan di sini.
class SimulatedVerificationService implements VerificationService {
  SimulatedVerificationService({
    this.stepDuration = const Duration(milliseconds: 1200),
  });

  final Duration stepDuration;

  static const List<VerificationState> _sequence = [
    VerificationState.detectingFace,
    VerificationState.detectingMedicine,
    VerificationState.analyzingPose,
    VerificationState.verifying,
  ];

  bool _cancelled = false;

  @override
  Stream<VerificationState> start() async* {
    _cancelled = false;

    for (final state in _sequence) {
      if (_cancelled) return;
      yield state;
      await Future<void>.delayed(stepDuration);
    }

    if (_cancelled) return;
    yield VerificationState.success;
  }

  @override
  void cancel() => _cancelled = true;
}
