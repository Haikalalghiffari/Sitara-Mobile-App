import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

import '../pages/medicine_refill_page.dart';

class MedicineOrderButton extends StatelessWidget {
  const MedicineOrderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicineRefillPage(),
                ),
              );
            },
            child: const Text(
              "Pesan Ulang Obat",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Lapor Darurat Jika ada masalah dengan ketersediaan Obat anda",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}