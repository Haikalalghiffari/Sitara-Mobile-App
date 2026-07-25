import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});

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
              size: 24,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            "Notifikasi",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.primary,
          ),
          onSelected: (value) {
            // TODO:
            // nanti isi menu
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: "read",
              child: Text("Tandai semua dibaca"),
            ),
            PopupMenuItem(
              value: "delete",
              child: Text("Hapus semua"),
            ),
          ],
        ),
      ],
    );
  }
}