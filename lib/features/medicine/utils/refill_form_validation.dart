/// Validasi dasar form pesan ulang, sebelum `POST /refills`.
class RefillFormValidation {
  const RefillFormValidation._();

  static const int minQuantity = 1;

  /// Quantity harus sama dengan stok obat yang dipilih.
  static String? validateLockedQuantity({
    required int quantity,
    required int stock,
  }) {
    if (stock < minQuantity) {
      return 'Stok obat tidak tersedia untuk pesan ulang.';
    }
    if (quantity < minQuantity) {
      return 'Jumlah yang diminta minimal $minQuantity.';
    }
    if (quantity > stock) {
      return 'Jumlah tidak boleh melebihi stok ($stock).';
    }
    if (quantity != stock) {
      return 'Jumlah harus sesuai stok obat yang dipilih ($stock).';
    }
    return null;
  }

  static String? validateSingle({
    required bool hasTreatment,
    required bool hasMedicine,
    required String? reason,
    required bool confirmed,
    required int quantity,
    required int stock,
  }) {
    final String? base = validate(
      hasTreatment: hasTreatment,
      hasMedicine: hasMedicine,
      reason: reason,
      quantity: quantity,
      confirmed: confirmed,
    );
    if (base != null) return base;
    return validateLockedQuantity(quantity: quantity, stock: stock);
  }

  static bool canSubmitSingle({
    required bool hasTreatment,
    required bool hasMedicine,
    required String? reason,
    required bool confirmed,
    required int quantity,
    required int stock,
  }) {
    return validateSingle(
          hasTreatment: hasTreatment,
          hasMedicine: hasMedicine,
          reason: reason,
          confirmed: confirmed,
          quantity: quantity,
          stock: stock,
        ) ==
        null;
  }

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

class RefillHistoryFetch {
  const RefillHistoryFetch._();

  static bool skipDuplicate({required bool inFlight}) => inFlight;
}
