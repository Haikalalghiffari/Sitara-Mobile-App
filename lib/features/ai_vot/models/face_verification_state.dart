/// Enum status state machine verifikasi wajah pasien saat sebelum minum obat.
enum FaceVerificationState {
  initial,
  capturing,
  verifying,
  verified,
  failed,
}
