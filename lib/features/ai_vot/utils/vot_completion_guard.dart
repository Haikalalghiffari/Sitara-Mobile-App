/// Mencegah `/vot/complete` dikirim dua kali untuk satu sesi.
class VotCompletionGuard {
  bool _inFlight = false;
  bool _succeeded = false;

  bool get inFlight => _inFlight;
  bool get succeeded => _succeeded;
  bool get canRequest => !_inFlight && !_succeeded;

  /// Memulai request. False jika sudah berjalan atau sudah sukses.
  bool tryBegin() {
    if (!canRequest) return false;
    _inFlight = true;
    return true;
  }

  void markSuccess() {
    _inFlight = false;
    _succeeded = true;
  }

  void markFailure() {
    _inFlight = false;
  }

  /// Sesi baru: complete boleh dikirim lagi dengan ID dari `/vot/start` berikutnya.
  void reset() {
    _inFlight = false;
    _succeeded = false;
  }
}
