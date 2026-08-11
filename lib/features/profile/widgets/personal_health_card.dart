import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/patient_profile.dart';

/// Hanya Nomor Rekam Medis yang berasal dari backend (PatientResponse).
///
/// Fasilitas Kesehatan dan Alamat Fasilitas tidak punya padanan di backend:
/// PatientResponse, TreatmentResponse, maupun ControlScheduleResponse tidak
/// memuat nama faskes, alamat faskes, latitude, atau longitude. PatientResponse
/// memang punya `address`, tetapi itu alamat rumah pasien, bukan alamat
/// fasilitas, sehingga tidak boleh dipakai di sini.
///
/// Dokter Penanggung Jawab ada sebagai TreatmentResponse.doctor_name, tetapi
/// hanya dapat dijangkau lewat treatment_id yang belum bisa diperoleh pasien
/// secara sah.
class PersonalHealthCard extends StatelessWidget {
  const PersonalHealthCard({
    super.key,
    required this.patient,
  });

  final PatientProfile patient;

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: AppRadius.component,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------

        Text(
          "Informasi Kesehatan",
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
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),
          child: Column(
            children: [

              _buildInfoTile(
                context: context,
                icon: Icons.local_hospital_outlined,
                iconBackground: AppColors.primaryContainer,
                iconColor: AppColors.primary,
                title: "Fasilitas Kesehatan",
                value: "Belum tersedia",
              ),

              const Divider(),

              _buildInfoTile(
                context: context,
                icon: Icons.medical_services_outlined,
                iconBackground: AppColors.secondaryContainer,
                iconColor: AppColors.secondary,
                title: "Dokter Penanggung Jawab",
                value: "Belum tersedia",
              ),

              const Divider(),

              _buildInfoTile(
                context: context,
                icon: Icons.badge_outlined,
                iconBackground: AppColors.infoContainer,
                iconColor: AppColors.info,
                title: "Nomor Rekam Medis",
                value: patient.medicalRecordNumber.isNotEmpty
                    ? patient.medicalRecordNumber
                    : "Belum tersedia",
              ),

              const Divider(),

              _buildInfoTile(
                context: context,
                icon: Icons.location_on_outlined,
                iconBackground: AppColors.warningContainer,
                iconColor: AppColors.warning,
                title: "Alamat Fasilitas",
                value: "Belum tersedia",
              ),
            ],
          ),
        ),
      ],
    );
  }
}