import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';

import '../../login/pages/login_page.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: () {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text("Logout"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari akun ini?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );
},

        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xffE53935),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),

        icon: const Icon(
          Icons.logout_rounded,
          size: 22,
        ),

        label: const Text(
          "Keluar",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}