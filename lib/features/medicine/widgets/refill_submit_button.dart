import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

/// Tombol kirim permintaan pesan ulang.
///
/// [isSubmitting] menonaktifkan tombol selama `POST /refills` berlangsung agar
/// permintaan yang sama tidak terkirim berkali-kali.
class RefillSubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSubmitting;

  const RefillSubmitButton({
    super.key,
    this.onPressed,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
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
              ),
        label: Text(
          isSubmitting ? "Mengirim..." : "Kirim Permintaan",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
