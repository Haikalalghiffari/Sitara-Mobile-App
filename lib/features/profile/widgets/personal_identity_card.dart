import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class PersonalIdentityCard extends StatelessWidget {
  const PersonalIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------

        Row(
          children: [

            Text(
              "Identitas Pribadi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const Spacer(),

            TextButton.icon(
              onPressed: () {},

              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),

              label: const Text(
                "Ubah",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // CARD
        //--------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //------------------------------------------
              // Nama
              //------------------------------------------

              Text(
                "Nama Lengkap",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                "Budi Santoso",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 22),

              //------------------------------------------
              // NIK
              //------------------------------------------

              Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "NIK (Nomor Induk Kependudukan)",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "32750********0001",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {},

                    icon: const Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              //------------------------------------------
              // Gender + Tanggal Lahir
              //------------------------------------------

              Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Jenis Kelamin",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Laki-laki",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Tanggal Lahir",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "12 Mei 1982",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}