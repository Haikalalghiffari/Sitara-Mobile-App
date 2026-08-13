import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Input jumlah obat yang diminta.
///
/// `RefillCreate.quantity` wajib diisi backend, sedangkan sebelumnya form ini
/// tidak mengumpulkan jumlah sama sekali. Nilainya diambil dari pasien, bukan
/// diisi otomatis, karena hanya pasien yang tahu berapa banyak obat yang perlu
/// diganti.
///
/// Satuan obat sengaja tidak disebut: `MyMedicineScheduleResponse` tidak
/// mengirim satuan, dan menuliskan "tablet" atau "butir" berarti mengarang.
class RefillQuantityField extends StatelessWidget {
  const RefillQuantityField({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.enabled = true,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool enabled;

  static const int minQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = enabled && quantity > minQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Jumlah yang Diminta",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onPressed: canDecrease
                    ? () => onChanged(quantity - 1)
                    : null,
              ),

              Expanded(
                child: Text(
                  "$quantity",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              _StepperButton(
                icon: Icons.add,
                onPressed: enabled
                    ? () => onChanged(quantity + 1)
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Sesuaikan dengan jumlah pada kemasan obat Anda.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return SizedBox(
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.component,
          ),
        ),
        icon: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textDisabled,
        ),
      ),
    );
  }
}
