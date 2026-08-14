import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../login/models/user_profile.dart';
import '../../progress/models/my_treatment.dart';
import '../../settings/pages/change_profile_picture_page.dart';
import '../models/patient_profile.dart';

/// Menampilkan data profil yang diberikan oleh [ProfilePage].
///
/// Widget ini sengaja tidak memanggil API sendiri agar tetap murni sebagai
/// lapisan tampilan.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.patient,
    required this.user,
    this.progress,
  });

  final PatientProfile patient;
  final UserProfile user;

  /// Perhitungan waktu terapi yang sama dengan ProgressPage.
  final TreatmentProgress? progress;

  /// Backend dapat mengirim `full_name` kosong bila data pasien belum
  /// dilengkapi petugas, sehingga username dipakai sebagai cadangan.
  String get _displayName =>
      patient.fullName.isNotEmpty ? patient.fullName : user.username;

  /// Nomor rekam medis adalah identitas pasien yang ditampilkan pada desain.
  /// Bila belum terisi, id user dipakai agar chip tidak tampil kosong.
  String get _identityLabel => patient.medicalRecordNumber.isNotEmpty
      ? "ID Pasien: ${patient.medicalRecordNumber}"
      : "ID User: ${user.id}";

  /// Label kepatuhan yang sama dengan ProgressSummaryCard.
  ///
  /// Null/`—` bila belum ada treatment atau terapi belum berjalan, supaya
  /// 100% tidak tampil tanpa data pengobatan.
  String get _adherenceLabel {
    final double? value = progress?.assumedAdherence;
    if (value == null) return "—";
    return "${(value * 100).round()}%";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          /// Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/profile.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangeProfilePicturePage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _identityLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          const SizedBox(height: 26),

          // Masa pengobatan memakai TreatmentProgress.totalDays, rumus yang
          // sama dengan ProgressTimelineCard. Kepatuhan memakai
          // assumedAdherence yang sama dengan ProgressSummaryCard.
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        progress == null
                            ? "—"
                            : "${progress!.totalDays} hari",
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Masa Pengobatan",
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),

                VerticalDivider(
                  color: AppColors.outlineVariant,
                  thickness: 1,
                ),

                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _adherenceLabel,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Kepatuhan",
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}