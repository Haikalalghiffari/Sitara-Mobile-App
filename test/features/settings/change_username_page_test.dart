import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/login/services/auth_service.dart';
import 'package:sitara/features/settings/pages/change_password_page.dart';

void main() {
  testWidgets('judul dan form username tampil tanpa menghapus password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: _FakeAuthService()),
      ),
    );

    expect(find.text('Ubah Username & Password'), findsOneWidget);
    expect(find.text('Username Baru'), findsOneWidget);
    expect(find.text('Ubah Username'), findsOneWidget);
    expect(find.text('Password Saat Ini'), findsOneWidget);
    expect(find.text('Ubah Password'), findsOneWidget);
  });

  testWidgets('username kosong menampilkan validasi', (WidgetTester tester) async {
    final _FakeAuthService auth = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    await tester.tap(find.text('Ubah Username'));
    await tester.pump();

    expect(find.text('Silakan masukkan username baru.'), findsOneWidget);
    expect(auth.usernameCalls, 0);
  });

  testWidgets('username terlalu pendek menampilkan validasi', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService auth = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.tap(find.text('Ubah Username'));
    await tester.pump();

    expect(find.text('Username baru minimal 3 karakter.'), findsOneWidget);
    expect(auth.usernameCalls, 0);
  });

  testWidgets('sukses menampilkan pesan backend dan mengosongkan input', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService auth = _FakeAuthService(
      usernameMessage: 'Username berhasil diubah.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'pasienbaru');
    await tester.tap(find.text('Ubah Username'));
    await tester.pump();
    await tester.pump();

    expect(auth.usernameCalls, 1);
    expect(auth.lastUsername, 'pasienbaru');
    expect(find.text('Username berhasil diubah.'), findsOneWidget);
    expect(find.text('pasienbaru'), findsNothing);
  });

  testWidgets('error API ditampilkan', (WidgetTester tester) async {
    final _FakeAuthService auth = _FakeAuthService(
      usernameError: const ApiException(
        'Username sudah digunakan.',
        statusCode: 400,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'sudahada');
    await tester.tap(find.text('Ubah Username'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Username sudah digunakan.'), findsOneWidget);
  });

  testWidgets('loading tampil selama request username', (
    WidgetTester tester,
  ) async {
    final Completer<String> completer = Completer<String>();
    final _FakeAuthService auth = _FakeAuthService(
      usernameCompleter: completer,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'pasienbaru');
    await tester.tap(find.text('Ubah Username'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete('Username berhasil diubah.');
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Username berhasil diubah.'), findsOneWidget);
  });

  testWidgets('ubah password existing tetap mengirim password', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService auth = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(authService: auth),
      ),
    );

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'PasswordLama1');
    await tester.enterText(fields.at(2), 'PasswordBaru1');
    await tester.enterText(fields.at(3), 'PasswordBaru1');
    await tester.ensureVisible(find.text('Ubah Password'));
    await tester.tap(find.text('Ubah Password'));
    await tester.pump();
    await tester.pump();

    expect(auth.passwordCalls, 1);
    expect(auth.lastCurrentPassword, 'PasswordLama1');
    expect(auth.lastNewPassword, 'PasswordBaru1');
    expect(auth.usernameCalls, 0);
    expect(find.text('Password berhasil diubah.'), findsOneWidget);
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.usernameMessage = 'Username berhasil diubah.',
    this.usernameError,
    this.usernameCompleter,
  });

  final String usernameMessage;
  final ApiException? usernameError;
  final Completer<String>? usernameCompleter;

  String? lastUsername;
  String? lastCurrentPassword;
  String? lastNewPassword;
  int usernameCalls = 0;
  int passwordCalls = 0;

  @override
  Future<String> changeUsername({required String newUsername}) async {
    usernameCalls += 1;
    lastUsername = newUsername;
    if (usernameCompleter != null) {
      return usernameCompleter!.future;
    }
    if (usernameError != null) {
      throw usernameError!;
    }
    return usernameMessage;
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordCalls += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return 'Password berhasil diubah.';
  }

  @override
  Future<void> logout() async {}
}
