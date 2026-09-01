import '../models/verification_state.dart';
import 'verification_service.dart';

/// Tidak dipakai halaman AI-VOT. Disimpan agar kontrak lama tetap compile.
class SimulatedVerificationService implements VerificationService {
  SimulatedVerificationService({
    this.stepDuration = const Duration(milliseconds: 1200),
  });

  final Duration stepDuration;

  static const List<VerificationState> _sequence = [
    VerificationState.starting,
    VerificationState.faceVerifying,
    VerificationState.medicineDetecting,
    VerificationState.drinking,
  ];

  bool _cancelled = false;

  @override
  Stream<VerificationState> start() async* {
    _cancelled = false;

    for (final VerificationState state in _sequence) {
      if (_cancelled) return;
      yield state;
      await Future<void>.delayed(stepDuration);
    }

    if (_cancelled) return;
    yield VerificationState.completed;
  }

  @override
  void cancel() => _cancelled = true;
}
