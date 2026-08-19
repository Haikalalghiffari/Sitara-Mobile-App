import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/indonesian_date.dart';
import '../../../shared/widgets/sitara_text_field.dart';

import '../models/patient_profile.dart';

/// Identitas pasien yang hanya boleh dibaca.
///
/// Nama, NIK, tanggal lahir, dan jenis kelamin berasal dari
/// `GET /patients/profile` dan tidak dikirim ulang ke server.
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

  late final TextEditingController _nameController;
  late final TextEditingController _nikController;
  late final TextEditingController _genderController;
  late final TextEditingController _birthDateController;

  /// NIK adalah data sensitif, jadi disembunyikan sampai pengguna memintanya.
  bool _isNikVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _nameText);
    _nikController = TextEditingController(text: _nikText);
    _genderController = TextEditingController(text: _genderText);
    _birthDateController = TextEditingController(text: _birthDateText);
  }

  @override
  void didUpdateWidget(covariant PersonalIdentityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      _nameController.text = _nameText;
      _nikController.text = _nikText;
      _genderController.text = _genderText;
      _birthDateController.text = _birthDateText;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _genderController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String get _nameText => widget.patient.fullName.isNotEmpty
      ? widget.patient.fullName
      : _unavailable;

  String get _nikText {
    final String nik = widget.patient.nik;
    if (nik.isEmpty) return _unavailable;
    return _isNikVisible ? nik : _maskNik(nik);
  }

  String get _genderText => _formatGender(widget.patient.gender);

  String get _birthDateText => _formatBirthDate(widget.patient.birthDate);

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

  static String _formatBirthDate(String birthDate) {
    if (birthDate.isEmpty) return _unavailable;

    final DateTime? date = DateTime.tryParse(birthDate);
    if (date == null) return birthDate;

    return formatIndonesianDate(date) ?? birthDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Identitas Pribadi",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

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

              SitaraTextField(
                label: "Nama Lengkap",
                labelIcon: Icons.badge_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _nameController,
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "NIK (Nomor Induk Kependudukan)",
                labelIcon: Icons.credit_card_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _nikController,
                suffixIcon: IconButton(
                  onPressed: widget.patient.nik.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _isNikVisible = !_isNikVisible;
                            _nikController.text = _nikText;
                          });
                        },
                  icon: Icon(
                    _isNikVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "Jenis Kelamin",
                labelIcon: Icons.wc_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _genderController,
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "Tanggal Lahir",
                labelIcon: Icons.calendar_today_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _birthDateController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
