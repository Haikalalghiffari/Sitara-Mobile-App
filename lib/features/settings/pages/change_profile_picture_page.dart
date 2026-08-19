import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../profile/widgets/profile_notice.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_save_button.dart';

/// Halaman ubah foto profil.
///
/// Kamera dan galeri dibuka di perangkat. Backend belum menyediakan endpoint
/// unggah foto, jadi foto yang dipilih hanya ditampilkan sebagai pratinjau
/// dan tidak diklaim sudah tersimpan.
class ChangeProfilePicturePage extends StatefulWidget {
  const ChangeProfilePicturePage({super.key});

  @override
  State<ChangeProfilePicturePage> createState() =>
      _ChangeProfilePicturePageState();
}

class _ChangeProfilePicturePageState extends State<ChangeProfilePicturePage> {
  final ImagePicker _picker = ImagePicker();

  File? _previewFile;
  bool _isPicking = false;

  Future<void> _pickFromCamera() async {
    if (_isPicking) return;

    final PermissionStatus status = await Permission.camera.request();

    if (!mounted) return;

    if (status.isGranted) {
      await _pick(ImageSource.camera);
      return;
    }

    if (status.isPermanentlyDenied) {
      showProfileNotice(
        context,
        "Izin kamera ditolak permanen. Buka pengaturan aplikasi untuk mengizinkannya.",
      );
      await openAppSettings();
      return;
    }

    showProfileNotice(
      context,
      "Izin kamera diperlukan untuk mengambil foto profil.",
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;

    await _pick(ImageSource.gallery);
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _isPicking = true;
    });

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (file == null) {
        return;
      }

      setState(() {
        _previewFile = File(file.path);
      });
    } on Exception {
      if (!mounted) return;

      showProfileNotice(
        context,
        source == ImageSource.camera
            ? "Kamera tidak dapat dibuka. Silakan coba lagi."
            : "Galeri tidak dapat dibuka. Silakan coba lagi.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _onSave() {
    showProfileNotice(context, profilePictureUploadUnavailableMessage);
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsHeader(title: "Ubah Foto Profil"),

                  const SizedBox(height: 36),

                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: _previewFile == null
                            ? Image.asset(
                                "assets/images/profile.png",
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _previewFile!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    _previewFile == null
                        ? "Pilih foto dari kamera atau galeri. Foto belum disimpan ke server."
                        : "Pratinjau foto yang dipilih. Foto ini belum disimpan ke server.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 32),

                  _SourceButton(
                    icon: Icons.photo_camera_outlined,
                    label: "Kamera",
                    enabled: !_isPicking,
                    onPressed: _pickFromCamera,
                  ),

                  const SizedBox(height: 14),

                  _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: "Galeri",
                    enabled: !_isPicking,
                    onPressed: _pickFromGallery,
                  ),

                  const SizedBox(height: 24),

                  SettingsSaveButton(
                    label: "Simpan Foto",
                    onPressed: _onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight + 4,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
