import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class FAQSectionHeader extends StatelessWidget {
  const FAQSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Pertanyaan Umum (FAQ)",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        TextButton(
          onPressed: () {
            // TODO:
            // Nanti dapat diarahkan ke halaman semua FAQ
          },
          child: const Text(
            "Lihat Semua",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}