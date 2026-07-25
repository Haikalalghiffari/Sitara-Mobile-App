import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

class NotificationFilterTabs extends StatelessWidget {
  const NotificationFilterTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [

          _FilterChip(
            label: "Semua",
            selected: true,
          ),

          SizedBox(width: 10),

          _FilterChip(
            label: "Obat",
          ),

          SizedBox(width: 10),

          _FilterChip(
            label: "Pesan",
          ),

          SizedBox(width: 10),

          _FilterChip(
            label: "Progres",
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.button,
      onTap: () {
        // TODO
        // nanti dibuat dengan Riverpod
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white,
          borderRadius: AppRadius.button,
          border: Border.all(
            color: AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}