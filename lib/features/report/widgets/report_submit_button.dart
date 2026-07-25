import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ReportSubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const ReportSubmitButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight + 4,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,

        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                size: 22,
                color: Colors.white,
              ),

        label: Text(
          isLoading ? "Mengirim..." : "Kirim Laporan",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),

        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),
      ),
    );
  }
}