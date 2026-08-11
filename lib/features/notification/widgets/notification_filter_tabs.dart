import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

class NotificationFilterTabs extends StatelessWidget {
  const NotificationFilterTabs({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  /// Label kategori. Ditentukan pemanggil karena kategori yang sah hanya yang
  /// benar-benar dikenal backend lewat field `type`.
  final List<String> filters;

  /// Kategori yang sedang aktif, harus salah satu dari [filters].
  final String selected;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final String filter in filters) ...[
            if (filter != filters.first) const SizedBox(width: 10),

            _FilterChip(
              label: filter,
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.button,
      onTap: onTap,
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