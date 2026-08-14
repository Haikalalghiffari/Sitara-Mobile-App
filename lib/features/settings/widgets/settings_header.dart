import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Header kembali yang sama polanya dengan Bantuan dan Pengaturan Notifikasi.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
