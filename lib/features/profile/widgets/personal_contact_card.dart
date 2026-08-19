import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';

import '../models/patient_profile.dart';

/// Kontak pasien.
///
/// Nomor telepon dan alamat tempat tinggal boleh diubah. Kontak PMO hanya
/// ditampilkan. Alamat email tidak ditampilkan sesuai keputusan produk.
class PersonalContactCard extends StatefulWidget {
  const PersonalContactCard({
    super.key,
    required this.patient,
    required this.phoneController,
    required this.addressController,
    this.enabled = true,
  });

  final PatientProfile patient;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool enabled;

  @override
  State<PersonalContactCard> createState() => _PersonalContactCardState();
}

class _PersonalContactCardState extends State<PersonalContactCard> {
  static const String _unavailable = "Belum tersedia";

  late final TextEditingController _pmoController;

  /// Pengawas Menelan Obat berperan sebagai kontak yang dihubungi petugas.
  String get _pmoContact {
    final String name = widget.patient.pmoName.trim();
    final String phone = widget.patient.pmoPhone.trim();

    if (name.isEmpty && phone.isEmpty) return _unavailable;
    if (name.isEmpty) return phone;
    if (phone.isEmpty) return name;

    return "$name • $phone";
  }

  @override
  void initState() {
    super.initState();
    _pmoController = TextEditingController(text: _pmoContact);
  }

  @override
  void didUpdateWidget(covariant PersonalContactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      _pmoController.text = _pmoContact;
    }
  }

  @override
  void dispose() {
    _pmoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Informasi Kontak",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          "Hanya nomor telepon dan alamat tempat tinggal yang dapat diubah.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
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
            children: [

              SitaraTextField(
                label: "Nomor Telepon",
                labelIcon: Icons.phone_outlined,
                hint: "08xxxxxxxxxx",
                controller: widget.phoneController,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "Alamat Tempat Tinggal",
                labelIcon: Icons.location_on_outlined,
                hint: "Alamat tempat tinggal",
                controller: widget.addressController,
                enabled: widget.enabled,
                maxLines: 3,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "Kontak Darurat (PMO)",
                labelIcon: Icons.emergency_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _pmoController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
