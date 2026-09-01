import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

class VerificationInfo extends StatelessWidget {
  const VerificationInfo({
    super.key,
    this.medicineName,
    this.scheduleMessage,
  });

  final String? medicineName;
  final String? scheduleMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? name = medicineName?.trim();
    final String? schedule = scheduleMessage?.trim();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: AppSpacing.iconSm,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                "Foto wajah dan obat dikirim ke server. Proses minum dinilai di perangkat.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (schedule != null && schedule.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            schedule,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (name != null && name.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Jadwal hari ini: $name",
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ],
    );
  }
}
