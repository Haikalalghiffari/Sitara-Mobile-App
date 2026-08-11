import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({
    super.key,
    required this.onMarkAllRead,
    required this.onDeleteAll,
    this.isMenuEnabled = true,
  });

  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;

  /// Menu dimatikan ketika daftar kosong, karena tidak ada yang bisa ditandai
  /// maupun dihapus.
  final bool isMenuEnabled;

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
          enabled: isMenuEnabled,
          // Menempel pada tombolnya sendiri agar menu tidak keluar layar.
          position: PopupMenuPosition.under,
          icon: Icon(
            Icons.more_vert,
            color: isMenuEnabled
                ? AppColors.primary
                : AppColors.textDisabled,
          ),
          onSelected: (value) {
            switch (value) {
              case "read":
                onMarkAllRead();
                break;

              case "delete":
                onDeleteAll();
                break;
            }
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