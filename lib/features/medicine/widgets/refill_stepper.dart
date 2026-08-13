import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class RefillStepper extends StatelessWidget {
  /// Langkah yang sudah dicapai, 1 sampai 3.
  ///
  /// Nilai bawaannya 1 sehingga tampilan sama seperti sebelumnya. Halaman
  /// menaikkannya menjadi 3 hanya setelah `POST /refills` benar-benar berhasil.
  final int currentStep;

  const RefillStepper({
    super.key,
    this.currentStep = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStep(
              number: "1",
              label: "Informasi",
              active: currentStep >= 1,
            ),

            Expanded(
              child: Divider(
                thickness: 2,
                color: Colors.grey.shade300,
              ),
            ),

            _buildStep(
              number: "2",
              label: "Review",
              active: currentStep >= 2,
            ),

            Expanded(
              child: Divider(
                thickness: 2,
                color: Colors.grey.shade300,
              ),
            ),

            _buildStep(
              number: "3",
              label: "Selesai",
              active: currentStep >= 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String label,
    bool active = false,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor:
              active ? AppColors.primary : AppColors.secondaryContainer,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppColors.primary : Colors.black54,
          ),
        ),
      ],
    );
  }
}