import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_save_button.dart';

/// Form informasi diri. Tahap ini hanya UI, tanpa mengambil atau mengirim API.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController =
      TextEditingController(text: "Nama Lengkap");
  final TextEditingController _nikController =
      TextEditingController(text: "16 digit NIK");
  final TextEditingController _birthDateController =
      TextEditingController(text: "01 Januari 1990");
  final TextEditingController _genderController =
      TextEditingController(text: "Laki-laki");
  final TextEditingController _phoneController =
      TextEditingController(text: "08xxxxxxxxxx");
  final TextEditingController _addressController =
      TextEditingController(text: "Alamat tempat tinggal");
  final TextEditingController _occupationController =
      TextEditingController(text: "Pekerjaan");

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _onSave() {
    // TODO: Integrasikan dengan endpoint update patient/profile ketika backend tersedia.
    // Nilai di form adalah placeholder UI dan tidak dikirim ke server.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsHeader(title: "Informasi Diri"),

                  const SizedBox(height: 28),

                  Text(
                    "Ubah informasi pribadi Anda. Perubahan belum dikirim ke server.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 28),

                  SitaraTextField(
                    label: "Nama Lengkap",
                    labelIcon: Icons.badge_outlined,
                    hint: "Nama lengkap sesuai identitas",
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "NIK",
                    labelIcon: Icons.credit_card_outlined,
                    hint: "16 digit NIK",
                    controller: _nikController,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Tanggal Lahir",
                    labelIcon: Icons.calendar_today_outlined,
                    hint: "Pilih tanggal lahir",
                    controller: _birthDateController,
                    readOnly: true,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Jenis Kelamin",
                    labelIcon: Icons.wc_outlined,
                    hint: "Laki-laki atau Perempuan",
                    controller: _genderController,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Nomor Telepon",
                    labelIcon: Icons.phone_outlined,
                    hint: "08xxxxxxxxxx",
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Alamat",
                    labelIcon: Icons.location_on_outlined,
                    hint: "Alamat tempat tinggal",
                    controller: _addressController,
                    maxLines: 3,
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Pekerjaan",
                    labelIcon: Icons.work_outline,
                    hint: "Pekerjaan",
                    controller: _occupationController,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 32),

                  SettingsSaveButton(
                    label: "Simpan Perubahan",
                    onPressed: _onSave,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
