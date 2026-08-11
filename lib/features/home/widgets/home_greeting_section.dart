import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

import '../../login/models/user_profile.dart';
import '../../profile/models/patient_profile.dart';

class HomeGreetingSection extends StatelessWidget {
  const HomeGreetingSection({
    super.key,
    this.patient,
    this.user,
    this.errorMessage,
    this.onRetry,
  });

  /// Bernilai null selama data profil masih dimuat atau gagal dimuat.
  final PatientProfile? patient;
  final UserProfile? user;

  final String? errorMessage;
  final VoidCallback? onRetry;

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return "Selamat Pagi";
    } else if (hour < 15) {
      return "Selamat Siang";
    } else if (hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  /// Nama pasien adalah sumber utama; username hanya dipakai bila
  /// `full_name` belum diisi petugas.
  String? get _displayName {
    final String fullName = patient?.fullName.trim() ?? "";
    if (fullName.isNotEmpty) return fullName;

    final String username = user?.username.trim() ?? "";
    if (username.isNotEmpty) return username;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? name = _displayName;
    final String greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null ? greeting : "$greeting, $name",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          "Tetap kuat dalam perjalananmu menuju kesehatan.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),

        // Hanya muncul saat profil gagal dimuat, sehingga tampilan normal
        // tetap sama persis seperti desain.
        if (errorMessage != null) ...[
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),

              const SizedBox(width: 8),

              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Coba Lagi"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
