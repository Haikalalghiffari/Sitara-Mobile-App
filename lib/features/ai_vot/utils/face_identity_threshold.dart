/// Ambang identitas wajah pada tahap FACE VOT.
///
/// Hanya dipakai untuk memutuskan lolos/gagal identitas dari
/// `similarity_score` hasil `POST /vot/face-verify`. Bukan ambang drinking,
/// bukan confidence obat, dan bukan pendaftaran wajah.
class FaceIdentityThreshold {
  const FaceIdentityThreshold._();

  /// Nilai minimum kemiripan agar identitas dianggap cocok.
  static const double value = 0.63;

  /// `similarity >= 0.63` → lolos; di bawah itu gagal.
  static bool isMet(double similarityScore) {
    return similarityScore >= value;
  }
}
