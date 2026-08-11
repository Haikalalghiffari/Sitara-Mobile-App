/// Response dari `GET /patients/profile`.
///
/// Field mengikuti persis apa yang dikirim backend, tanpa tambahan.
///
/// `birthDate`, `createdAt`, dan `updatedAt` sengaja disimpan sebagai [String]
/// apa adanya dari backend. Parsing ke [DateTime] baru dilakukan nanti ketika
/// UI benar-benar membutuhkan format tanggal, agar kegagalan parsing tidak
/// menggagalkan seluruh pemuatan profil.
class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.userId,
    required this.medicalRecordNumber,
    required this.fullName,
    required this.nik,
    required this.birthDate,
    required this.gender,
    required this.phone,
    required this.address,
    required this.occupation,
    required this.pmoName,
    required this.pmoPhone,
    required this.clinicalNote,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String medicalRecordNumber;
  final String fullName;
  final String nik;
  final String birthDate;
  final String gender;
  final String phone;
  final String address;
  final String occupation;
  final String pmoName;
  final String pmoPhone;
  final String clinicalNote;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      medicalRecordNumber: json['medical_record_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      pmoName: json['pmo_name']?.toString() ?? '',
      pmoPhone: json['pmo_phone']?.toString() ?? '',
      clinicalNote: json['clinical_note']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'PatientProfile(id: $id, userId: $userId, '
      'medicalRecordNumber: $medicalRecordNumber, fullName: $fullName)';
}
