import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class HomeGreetingSection extends StatelessWidget {
  const HomeGreetingSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_getGreeting()}, Azzam",
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
      ],
    );
  }
}