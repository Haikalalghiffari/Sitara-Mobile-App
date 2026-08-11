import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/patient_profile.dart';
import 'profile_notice.dart';

class PersonalInformationHeader extends StatelessWidget {
  const PersonalInformationHeader({
    super.key,
    required this.patient,
  });

  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        //--------------------------------------------------
        // APP BAR
        //--------------------------------------------------

        Row(
          children: [

            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
              ),
            ),

            Expanded(
              child: Text(
                "Informasi Pribadi",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),

            IconButton(
              onPressed: () => showProfileNotice(
                context,
                profileSettingsUnavailableMessage,
              ),
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        //--------------------------------------------------
        // PROFILE PHOTO
        //--------------------------------------------------

        Stack(
          alignment: Alignment.bottomRight,
          children: [

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/profile.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showProfileNotice(
                  context,
                  profileEditUnavailableMessage,
                ),
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        //--------------------------------------------------
        // NAME
        //--------------------------------------------------

        Text(
          patient.fullName.isNotEmpty ? patient.fullName : "Belum tersedia",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // STATUS BADGE
        //--------------------------------------------------

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.fullRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 18,
              ),

              const SizedBox(width: 8),

              // Hanya status aktif yang berasal dari backend (`is_active`).
              // Fase pengobatan sengaja tidak disebut karena TreatmentPhase
              // hanya ada pada TreatmentResponse yang belum dapat diakses
              // role patient.
              Text(
                patient.isActive
                    ? "Pasien Aktif"
                    : "Pasien Tidak Aktif",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}