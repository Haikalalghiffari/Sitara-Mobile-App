import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../widgets/refill_stepper.dart';
import '../widgets/refill_medicine_info_card.dart';
import '../widgets/refill_reason_section.dart';
import '../widgets/refill_detail_field.dart';
import '../widgets/refill_confirmation_section.dart';
import '../widgets/refill_submit_button.dart';

class MedicineRefillPage extends StatefulWidget {
  const MedicineRefillPage({super.key});

  @override
  State<MedicineRefillPage> createState() =>
      _MedicineRefillPageState();
}

class _MedicineRefillPageState extends State<MedicineRefillPage> {
  final TextEditingController detailController =
      TextEditingController();

  bool isConfirmed = false;

  @override
  void dispose() {
    detailController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final detail = detailController.text.trim();

    // Belum isi & belum centang
    if (detail.isEmpty && !isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Silakan isi keterangan dan centang persetujuan terlebih dahulu.",
          ),
        ),
      );
      return;
    }

    // Belum isi
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Silakan isi keterangan terlebih dahulu.",
          ),
        ),
      );
      return;
    }

    // Kurang dari 20 karakter
    if (detail.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Keterangan minimal 20 karakter.",
          ),
        ),
      );
      return;
    }

    // Belum checklist
    if (!isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Silakan centang pernyataan persetujuan.",
          ),
        ),
      );
      return;
    }

    // Berhasil
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    backgroundColor: Colors.green,
    duration: Duration(seconds: 1),
    content: Text(
      "Permintaan pesan ulang obat berhasil dikirim.",
    ),
  ),
);

// Kembali otomatis ke halaman Logistik Obat
Future.delayed(const Duration(seconds: 1), () {
  if (!mounted) return;

  Navigator.pop(context);
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Pesan Ulang Obat",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const RefillStepper(),

                  const SizedBox(height: 28),

                  const RefillMedicineInfoCard(),

                  const SizedBox(height: 32),

                  const RefillReasonSection(),

                  const SizedBox(height: 28),

                  RefillDetailField(
                    controller: detailController,
                  ),

                  const SizedBox(height: 32),

                  RefillConfirmationSection(
                    value: isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  RefillSubmitButton(
                    onPressed: _submitRequest,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}