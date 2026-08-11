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

    // Form sudah lengkap, tetapi permintaan TIDAK dikirim ke mana pun.
    // Menyatakan "berhasil dikirim" akan menyesatkan pasien.
    //
    // RefillCreate mewajibkan treatment_id, medicine_id, quantity, dan reason.
    // Saat ini tidak satu pun dari empat field itu punya sumber yang sah:
    // treatment_id dan medicine_id hanya bisa ditelusuri lewat GET /treatments
    // (require_nakes), quantity belum dikumpulkan form ini, dan reason yang
    // dipilih pasien masih tertahan di dalam state RefillReasonSection
    // sehingga belum terbaca halaman ini.
    //
    // TODO: Kirim POST /refills setelah backend menyediakan endpoint refill
    // yang dapat diakses role patient. Saat itu perlu ditambahkan: input
    // quantity, callback agar reason terbaca di halaman ini, isLoading pada
    // RefillSubmitButton untuk mencegah kiriman ganda, serta penanganan
    // ApiException.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Pesan ulang obat belum dapat dikirim dari aplikasi. Sampaikan kebutuhan ini kepada petugas kesehatan.",
        ),
      ),
    );
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