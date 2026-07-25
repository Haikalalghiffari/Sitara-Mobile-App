import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class RefillStepper extends StatelessWidget {
  const RefillStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStep(
              number: "1",
              label: "Informasi",
              active: true,
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