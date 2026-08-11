import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class NotificationEmpty extends StatelessWidget {
  const NotificationEmpty({
    super.key,
    this.title = "Belum ada notifikasi",
    this.message =
        "Semua aktivitas terbaru akan muncul di sini setelah tersedia.",
    this.icon = Icons.notifications_none_rounded,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primaryContainer,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Tombol tambahan, dipakai kartu ini saat menampilkan kegagalan pemuatan.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.outlineVariant,
          ),
        ),
        child: Column(
          children: [

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 38,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),

            if (actionLabel != null) ...[
              const SizedBox(height: 6),

              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}