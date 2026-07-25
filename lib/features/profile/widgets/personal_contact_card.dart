import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import 'contact_tile.dart';

class PersonalContactCard extends StatelessWidget {
  const PersonalContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------

        Text(
          "Informasi Kontak",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // CARD
        //--------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              ContactTile(
                icon: Icons.phone_outlined,
                iconBackground: AppColors.infoContainer,
                iconColor: AppColors.info,
                title: "Nomor Telepon",
                value: "+62 812 3456 7890",
                onTap: () {},
              ),

              const Divider(
                color: AppColors.outlineVariant,
                height: 1,
              ),

              ContactTile(
                icon: Icons.email_outlined,
                iconBackground: AppColors.secondaryContainer,
                iconColor: AppColors.secondary,
                title: "Alamat Email",
                value: "budi.santoso@email.com",
                onTap: () {},
              ),

              const Divider(
                color: AppColors.outlineVariant,
                height: 1,
              ),

              ContactTile(
                icon: Icons.emergency_outlined,
                iconBackground: AppColors.errorContainer,
                iconColor: AppColors.error,
                title: "Kontak Darurat",
                value: "Ani Santoso • +62 812 9999 8888",
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}