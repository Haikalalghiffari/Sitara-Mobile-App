import 'package:flutter/material.dart';

import '../../profile/pages/personal_information_page.dart';

/// Pintu masuk lama ke form informasi diri.
///
/// Semua data dan aturan suntingan ada di [PersonalInformationPage], supaya
/// tidak ada salinan form dengan data contoh.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonalInformationPage();
  }
}
