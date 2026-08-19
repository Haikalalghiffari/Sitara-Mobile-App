import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';

/// Input field reusable dengan label dan ikon.
class SitaraTextField extends StatelessWidget {
  const SitaraTextField({
    super.key,
    required this.label,
    required this.hint,
    this.labelIcon,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.labelTrailing,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final IconData? labelIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Widget? labelTrailing;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (labelIcon != null) ...[
              Icon(labelIcon, size: 18, color: AppColors.textLabel),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textLabel,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ?labelTrailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          textCapitalization: textCapitalization,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: readOnly || !enabled
                    ? AppColors.textSecondary
                    : AppColors.onSurfaceLight,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
            filled: true,
            fillColor: readOnly || !enabled
                ? AppColors.surfaceContainerLow
                : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: const BorderSide(color: AppColors.outlineVariantLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: const BorderSide(color: AppColors.outlineVariantLight),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: const BorderSide(color: AppColors.outlineVariantLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.lgRadius,
              borderSide: BorderSide(
                color: readOnly
                    ? AppColors.outlineVariantLight
                    : AppColors.healthPrimary,
                width: readOnly ? 1 : 1.5,
              ),
            ),
            suffixIcon: suffixIcon ??
                (readOnly
                    ? const Icon(
                        Icons.lock_outline,
                        color: AppColors.textHint,
                        size: 20,
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}
