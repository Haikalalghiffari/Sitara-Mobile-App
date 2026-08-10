import '../models/verification_state.dart';

/// Kontrak alur verifikasi minum obat.
///
/// UI hanya bergantung pada interface ini. Saat model AI sudah siap, cukup
/// menambahkan implementasi baru tanpa mengubah halaman maupun widget.
abstract interface class VerificationService {
  /// Menjalankan alur verifikasi dan memancarkan perubahan state secara
  /// berurutan hingga [VerificationState.success] atau
  /// [VerificationState.failed].
  Stream<VerificationState> start();

  /// Menghentikan alur yang sedang berjalan.
  void cancel();
}
