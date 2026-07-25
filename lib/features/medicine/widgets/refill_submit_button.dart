import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class RefillSubmitButton extends StatelessWidget {
  const RefillSubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          elevation: 0,
        ),
        onPressed: () {
          // TODO:
          // Nanti diarahkan ke halaman Review Permintaan
        },
        icon: const Icon(
          Icons.send_rounded,
          size: 22,
        ),
        label: const Text(
          "Kirim Permintaan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}