/// Validasi dasar form pesan ulang, sebelum `POST /refills`.
///
/// Tidak mengganti aturan backend. `description` opsional dan tidak divalidasi.
class RefillFormValidation {
  const RefillFormValidation._();

  static const int minQuantity = 1;

  static String? validate({
    required bool hasTreatment,
    required bool hasMedicine,
    required String? reason,
    required int quantity,
    required bool confirmed,
  }) {
    if (!hasTreatment) {
      return 'Pesan ulang belum dapat diajukan karena data pengobatan Anda belum tersedia. Hubungi petugas kesehatan.';
    }
    if (!hasMedicine) {
      return 'Pesan ulang belum dapat diajukan karena data obat Anda belum tersedia. Hubungi petugas kesehatan.';
    }
    if (reason == null || reason.trim().isEmpty) {
      return 'Silakan pilih alasan pesan ulang terlebih dahulu.';
    }
    if (quantity < minQuantity) {
      return 'Jumlah yang diminta minimal $minQuantity.';
    }
    if (!confirmed) {
      return 'Silakan centang pernyataan persetujuan.';
    }
    return null;
  }
}

/// Mencegah double-tap mengirim `POST /refills` dua kali.
class RefillSubmitLock {
  bool _locked = false;

  bool get isLocked => _locked;

  bool tryLock() {
    if (_locked) return false;
    _locked = true;
    return true;
  }

  void unlock() {
    _locked = false;
  }
}

/// Gerbang `GET /refills/my`. Spinner UI tidak boleh dipakai: frame pertama
/// sudah `loading = true`, tetapi HTTP belum jalan.
class RefillHistoryFetch {
  const RefillHistoryFetch._();

  static bool skipDuplicate({required bool inFlight}) => inFlight;
}
