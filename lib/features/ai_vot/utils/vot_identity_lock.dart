/// Kehadiran wajah selama sesi VOT yang identitasnya sudah terkunci.
///
/// Bukan kemiripan wajah. Nilai di sini hanya menjawab "apakah masih ada
/// wajah", tanpa membandingkan embedding apa pun.
enum FacePresenceStatus {
  /// Wajah terlihat pada frame ini.
  present,

  /// Wajah tidak terlihat, tetapi masih di dalam masa tenggang.
  lostWithinGrace,

  /// Wajah tidak terlihat melewati masa tenggang.
  lostTooLong,
}

/// Kunci identitas satu sesi VOT.
///
/// Face recognition hanya dipakai sekali di awal sesi. Setelah [lock],
/// identitas dianggap terkunci sampai sesi dibatalkan atau di-reset, sehingga
/// pasien yang menunduk, menoleh, mengangkat obat, atau menutupi wajah dengan
/// tangan tidak memicu verifikasi ulang maupun kegagalan.
class VotIdentityLock {
  /// Wajah boleh hilang selama ini tanpa mengganggu deteksi minum.
  static const Duration gracePeriod = Duration(seconds: 5);

  bool _identityVerified = false;
  DateTime? _lastFaceSeenAt;

  /// True setelah verifikasi identitas awal berhasil.
  bool get identityVerified => _identityVerified;

  /// Gerbang anti-spam: `POST /vot/face-verify` hanya boleh dipanggil saat ini
  /// bernilai true.
  bool get shouldVerifyIdentity => !_identityVerified;

  DateTime? get lastFaceSeenAt => _lastFaceSeenAt;

  /// Mengunci identitas sesi. Dipanggil sekali, setelah backend menyatakan
  /// wajah cocok, atau saat sesi yang dilanjutkan sudah melewati tahap wajah.
  void lock({required DateTime now}) {
    _identityVerified = true;
    _lastFaceSeenAt = now;
  }

  /// Menyegarkan penanda waktu wajah terakhir terlihat, misalnya saat tahap
  /// minum baru dimulai. Tidak mengunci identitas.
  void markFaceSeen(DateTime now) {
    if (!_identityVerified) return;
    _lastFaceSeenAt = now;
  }

  /// Melepas kunci. Hanya untuk sesi yang dibatalkan, ditinggalkan, atau
  /// di-reset; tidak pernah karena kemiripan wajah turun.
  void reset() {
    _identityVerified = false;
    _lastFaceSeenAt = null;
  }

  /// Berapa lama wajah sudah tidak terlihat. Null bila belum pernah terlihat.
  Duration? faceLostFor(DateTime now) {
    final DateTime? last = _lastFaceSeenAt;
    if (last == null) return null;
    final Duration lost = now.difference(last);
    return lost.isNegative ? Duration.zero : lost;
  }

  /// Pengecekan ringan berbasis hasil deteksi lokal.
  ///
  /// Tidak pernah mengubah [identityVerified]: wajah yang hilang terlalu lama
  /// hanya menghasilkan [FacePresenceStatus.lostTooLong] agar UI dapat
  /// memperingatkan, bukan menggagalkan sesi.
  FacePresenceStatus evaluate({
    required bool facePresent,
    required DateTime now,
  }) {
    if (facePresent) {
      _lastFaceSeenAt = now;
      return FacePresenceStatus.present;
    }

    final Duration? lost = faceLostFor(now);
    if (lost == null) {
      _lastFaceSeenAt = now;
      return FacePresenceStatus.lostWithinGrace;
    }

    if (lost < gracePeriod) return FacePresenceStatus.lostWithinGrace;
    return FacePresenceStatus.lostTooLong;
  }

  // ── Pesan UI ─────────────────────────────────────────────────────────────
  static const String identityVerifiedMessage =
      'Identitas berhasil diverifikasi';

  static const String takeMedicineMessage = 'Silakan ambil obat';

  /// Wajah hilang sesaat: pasien diberi tahu, proses minum tetap berjalan.
  static const String faceLostBrieflyMessage =
      'Wajah tidak terlihat sejenak. Lanjutkan minum obat.';

  /// Wajah hilang terlalu lama: peringatan, bukan kegagalan.
  static const String faceLostTooLongMessage =
      'Wajah tidak terlihat. Arahkan kamera ke wajah Anda, proses minum tetap '
      'dilanjutkan.';
}
