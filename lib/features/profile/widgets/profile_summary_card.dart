import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../login/models/user_profile.dart';
import '../models/patient_profile.dart';
import 'profile_notice.dart';

/// Menampilkan data profil yang diberikan oleh [ProfilePage].
///
/// Widget ini sengaja tidak memanggil API sendiri agar tetap murni sebagai
/// lapisan tampilan.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.patient,
    required this.user,
  });

  final PatientProfile patient;
  final UserProfile user;

  /// Backend dapat mengirim `full_name` kosong bila data pasien belum
  /// dilengkapi petugas, sehingga username dipakai sebagai cadangan.
  String get _displayName =>
      patient.fullName.isNotEmpty ? patient.fullName : user.username;

  /// Nomor rekam medis adalah identitas pasien yang ditampilkan pada desain.
  /// Bila belum terisi, id user dipakai agar chip tidak tampil kosong.
  String get _identityLabel => patient.medicalRecordNumber.isNotEmpty
      ? "ID Pasien: ${patient.medicalRecordNumber}"
      : "ID User: ${user.id}";

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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 4,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage(
                    "assets/images/profile.png",
                  ),
                ),
              ),

              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 38,
                  height: 38,
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
                    onPressed: () => showProfileNotice(
                      context,
                      profileEditUnavailableMessage,
                    ),
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

          // Kedua angka di bawah ini tidak punya sumber di backend.
          //
          // Masa pengobatan memerlukan `therapy_start_date` dari Treatment yang
          // belum dapat diakses role patient. Kepatuhan tidak ada sama sekali di
          // ERD, jadi tidak ada nilai yang bisa dihitung. Menampilkan angka di
          // sini akan membuat pasien menyimpulkan pengobatannya berjalan baik
          // padahal aplikasi tidak mengetahuinya.
          //
          // TODO: Isi dari backend setelah pasien punya cara sah membaca
          // treatment miliknya, dan setelah metrik kepatuhan tersedia.
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "—",
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
                        "—",
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