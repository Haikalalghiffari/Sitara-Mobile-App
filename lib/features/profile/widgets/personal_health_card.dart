import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';

import '../models/patient_profile.dart';

/// Data kesehatan yang ditampilkan dari `PatientResponse`.
///
/// Nomor rekam medis dan catatan klinis hanya boleh dibaca. Nama fasilitas
/// dan alamat fasilitas tidak ada di schema backend, jadi tidak ditampilkan.
/// Dokter penanggung jawab sengaja dihapus dari UI mobile.
class PersonalHealthCard extends StatefulWidget {
  const PersonalHealthCard({
    super.key,
    required this.patient,
  });

  final PatientProfile patient;

  @override
  State<PersonalHealthCard> createState() => _PersonalHealthCardState();
}

class _PersonalHealthCardState extends State<PersonalHealthCard> {
  static const String _unavailable = "Belum tersedia";

  late final TextEditingController _mrnController;
  late final TextEditingController _clinicalNoteController;

  @override
  void initState() {
    super.initState();
    _mrnController = TextEditingController(text: _mrnText);
    _clinicalNoteController = TextEditingController(text: _clinicalNoteText);
  }

  @override
  void didUpdateWidget(covariant PersonalHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      _mrnController.text = _mrnText;
      _clinicalNoteController.text = _clinicalNoteText;
    }
  }

  @override
  void dispose() {
    _mrnController.dispose();
    _clinicalNoteController.dispose();
    super.dispose();
  }

  String get _mrnText => widget.patient.medicalRecordNumber.isNotEmpty
      ? widget.patient.medicalRecordNumber
      : _unavailable;

  String get _clinicalNoteText {
    final String note = widget.patient.clinicalNote.trim();
    return note.isNotEmpty ? note : _unavailable;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Informasi Kesehatan",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

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

              SitaraTextField(
                label: "Nomor Rekam Medis",
                labelIcon: Icons.badge_outlined,
                hint: _unavailable,
                readOnly: true,
                controller: _mrnController,
              ),

              const SizedBox(height: AppSpacing.xl),

              SitaraTextField(
                label: "Catatan Klinis",
                labelIcon: Icons.notes_outlined,
                hint: _unavailable,
                readOnly: true,
                maxLines: 4,
                controller: _clinicalNoteController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
