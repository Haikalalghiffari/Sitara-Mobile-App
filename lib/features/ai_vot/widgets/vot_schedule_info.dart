import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Informasi jadwal AI-VOT (belum waktunya / sudah selesai / kosong).
///
/// Bukan error: tidak memakai warna error dan tidak menampilkan retry.
class VotScheduleInfo extends StatelessWidget {
  const VotScheduleInfo({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
