import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class HelpBanner extends StatelessWidget {
  const HelpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xffEAF6F5),
            borderRadius: AppRadius.cardLarge,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            "assets/images/help_doctor.png",
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          "Apa yang bisa kami bantu?",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 14),

        Text(
          "Temukan jawaban untuk pertanyaan Anda seputar SITARA Health. "
          "Kami telah menyiapkan berbagai informasi yang paling sering "
          "ditanyakan oleh pengguna.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}