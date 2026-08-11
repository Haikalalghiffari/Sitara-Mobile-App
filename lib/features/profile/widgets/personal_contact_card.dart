import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import 'contact_tile.dart';

import '../../login/models/user_profile.dart';
import '../models/patient_profile.dart';

class PersonalContactCard extends StatelessWidget {
  const PersonalContactCard({
    super.key,
    required this.patient,
    required this.user,
  });

  final PatientProfile patient;
  final UserProfile user;

  static const String _unavailable = "Belum tersedia";

  static String _orFallback(String value) =>
      value.isNotEmpty ? value : _unavailable;

  /// Pengawas Menelan Obat berperan sebagai kontak yang dihubungi petugas,
  /// sehingga mengisi slot kontak darurat pada desain.
  String get _pmoContact {
    final String name = patient.pmoName.trim();
    final String phone = patient.pmoPhone.trim();

    if (name.isEmpty && phone.isEmpty) return _unavailable;
    if (name.isEmpty) return phone;
    if (phone.isEmpty) return name;

    return "$name • $phone";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------

        Text(
          "Informasi Kontak",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // CARD
        //--------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              ContactTile(
                icon: Icons.phone_outlined,
                iconBackground: AppColors.infoContainer,
                iconColor: AppColors.info,
                title: "Nomor Telepon",
                value: _orFallback(patient.phone),
                onTap: () {},
              ),

              const Divider(
                color: AppColors.outlineVariant,
                height: 1,
              ),

              ContactTile(
                icon: Icons.email_outlined,
                iconBackground: AppColors.secondaryContainer,
                iconColor: AppColors.secondary,
                title: "Alamat Email",
                value: _orFallback(user.email),
                onTap: () {},
              ),

              const Divider(
                color: AppColors.outlineVariant,
                height: 1,
              ),

              ContactTile(
                icon: Icons.emergency_outlined,
                iconBackground: AppColors.errorContainer,
                iconColor: AppColors.error,
                title: "Kontak Darurat (PMO)",
                value: _pmoContact,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}