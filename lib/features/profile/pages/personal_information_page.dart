import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../widgets/personal_information_header.dart';
import '../widgets/personal_identity_card.dart';
import '../widgets/personal_contact_card.dart';
import '../widgets/personal_health_card.dart';
import '../widgets/privacy_note.dart';

class PersonalInformationPage extends StatelessWidget {
  const PersonalInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [

              PersonalInformationHeader(),

              SizedBox(height: 32),

              PersonalIdentityCard(),

              SizedBox(height: 28),

              PersonalContactCard(),

              SizedBox(height: 28),

              PersonalHealthCard(),

              SizedBox(height: 32),

              PrivacyNote(),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}