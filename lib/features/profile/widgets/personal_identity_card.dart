import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/patient_profile.dart';
import '../../settings/pages/edit_profile_page.dart';

class PersonalIdentityCard extends StatefulWidget {
  const PersonalIdentityCard({
    super.key,
    required this.patient,
  });

  final PatientProfile patient;

  @override
  State<PersonalIdentityCard> createState() => _PersonalIdentityCardState();
}

class _PersonalIdentityCardState extends State<PersonalIdentityCard> {
  static const String _unavailable = "Belum tersedia";

  static const List<String> _monthNames = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  /// NIK adalah data sensitif, jadi disembunyikan sampai pengguna memintanya.
  bool _isNikVisible = false;

  String get _nikText {
    final String nik = widget.patient.nik;
    if (nik.isEmpty) return _unavailable;
    return _isNikVisible ? nik : _maskNik(nik);
  }

  static String _maskNik(String nik) {
    if (nik.length <= 8) return nik;

    final String prefix = nik.substring(0, 4);
    final String suffix = nik.substring(nik.length - 4);
    return "$prefix${"*" * (nik.length - 8)}$suffix";
  }

  /// Backend mengirim `"male"` / `"female"`.
  static String _formatGender(String gender) {
    return switch (gender.toLowerCase()) {
      "male" => "Laki-laki",
      "female" => "Perempuan",
      "" => _unavailable,
      _ => gender,
    };
  }

  /// Backend mengirim tanggal ISO seperti `"2004-01-07"`.
  ///
  /// Nilai asli pada model tidak diubah; pemformatan hanya terjadi di sini.
  /// Bila formatnya tidak dikenali, nilai mentah tetap ditampilkan apa adanya.
  static String _formatBirthDate(String birthDate) {
    if (birthDate.isEmpty) return _unavailable;

    final DateTime? date = DateTime.tryParse(birthDate);
    if (date == null) return birthDate;

    return "${date.day} ${_monthNames[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final PatientProfile patient = widget.patient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------

        Row(
          children: [

            Text(
              "Identitas Pribadi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const Spacer(),

            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },

              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),

              label: const Text(
                "Ubah",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // CARD
        //--------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //------------------------------------------
              // Nama
              //------------------------------------------

              Text(
                "Nama Lengkap",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                patient.fullName.isNotEmpty ? patient.fullName : _unavailable,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 22),

              //------------------------------------------
              // NIK
              //------------------------------------------

              Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "NIK (Nomor Induk Kependudukan)",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _nikText,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: patient.nik.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _isNikVisible = !_isNikVisible;
                            });
                          },

                    icon: Icon(
                      _isNikVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              //------------------------------------------
              // Gender + Tanggal Lahir
              //------------------------------------------

              Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Jenis Kelamin",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _formatGender(patient.gender),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Tanggal Lahir",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _formatBirthDate(patient.birthDate),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              //------------------------------------------
              // Alamat
              //------------------------------------------

              // `address` pada PatientResponse adalah alamat tempat tinggal
              // pasien, bukan alamat fasilitas kesehatan.
              Text(
                "Alamat",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                patient.address.isNotEmpty ? patient.address : _unavailable,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
