import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Top bar halaman AI-VOT: tombol kembali, judul di tengah, tombol bantuan.
class AiVotTopBar extends StatelessWidget {
  const AiVotTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHelp,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;

  static const double _actionSize = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.appBarHeight,
      child: Row(
        children: [
          _TopBarAction(
            icon: Icons.arrow_back_ios_new,
            tooltip: "Kembali",
            onTap: onBack,
          ),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          if (onHelp != null)
            _TopBarAction(
              icon: Icons.help_outline_rounded,
              tooltip: "Bantuan",
              onTap: onHelp,
            )
          else
            const SizedBox(width: AiVotTopBar._actionSize),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AiVotTopBar._actionSize,
      height: AiVotTopBar._actionSize,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 22,
        icon: Icon(
          icon,
          size: 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
