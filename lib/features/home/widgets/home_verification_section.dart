import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class HomeVerificationSection extends StatelessWidget {
  const HomeVerificationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.dashboardOvalBackground,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Verifikasi Minum Obat",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 10),

          Text(
            "Gunakan kamera untuk memverifikasi bahwa obat telah diminum.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Buka Kamera"),
            ),
          ),
        ],
      ),
    );
  }
}