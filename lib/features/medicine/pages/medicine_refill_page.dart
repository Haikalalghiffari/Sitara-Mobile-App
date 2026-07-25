import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../widgets/refill_stepper.dart';
import '../widgets/refill_medicine_info_card.dart';
import '../widgets/refill_reason_section.dart';
import '../widgets/refill_detail_field.dart';
import '../widgets/refill_confirmation_section.dart';
import '../widgets/refill_submit_button.dart';

class MedicineRefillPage extends StatelessWidget {
  const MedicineRefillPage({super.key});

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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

                  RefillStepper(),

                  SizedBox(height: 28),

                  RefillMedicineInfoCard(),

                  SizedBox(height: 32),

                  RefillReasonSection(),

                  SizedBox(height: 28),

                  RefillDetailField(),

                  SizedBox(height: 32),

                  RefillConfirmationSection(),

                  SizedBox(height: 20),

                  RefillSubmitButton(),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}