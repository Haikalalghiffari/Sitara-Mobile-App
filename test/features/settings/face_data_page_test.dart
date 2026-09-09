import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/face_status.dart';
import 'package:sitara/features/ai_vot/pages/register_face_page.dart';
import 'package:sitara/features/ai_vot/services/face_service.dart';
import 'package:sitara/features/settings/pages/face_data_page.dart';
import 'package:sitara/features/settings/pages/settings_page.dart';

void main() {
  testWidgets('Settings menampilkan Data Wajah, bukan Pendaftaran Wajah', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );

    expect(find.text('Data Wajah'), findsOneWidget);
    expect(find.text('Kelola data wajah untuk verifikasi'), findsOneWidget);
    expect(find.text('Pendaftaran Wajah'), findsNothing);
    expect(find.text('Ubah Username & Password'), findsOneWidget);
    expect(find.text('Informasi Diri'), findsOneWidget);
  });

  testWidgets('1. status belum terdaftar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: false),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum terdaftar'), findsOneWidget);
    expect(find.text('Daftarkan Wajah'), findsOneWidget);
    expect(find.text('Perbarui Data Wajah'), findsNothing);
    expect(find.text('Wajah sudah terdaftar'), findsNothing);
  });

  testWidgets('2. status sudah terdaftar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: true),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('✓ Wajah sudah terdaftar'), findsOneWidget);
    expect(find.text('Perbarui Data Wajah'), findsOneWidget);
    expect(find.text('Daftarkan Wajah'), findsNothing);
    expect(find.text('Belum terdaftar'), findsNothing);
  });

  testWidgets('3. Daftarkan Wajah membuka existing Face Register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: false),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daftarkan Wajah'));
    await tester.pumpAndSettle();

    expect(find.byKey(_registerStubKey), findsOneWidget);
    expect(find.byType(RegisterFacePage), findsNothing);
  });

  testWidgets('4. Perbarui Data Wajah menampilkan confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: true),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui Data Wajah'));
    await tester.pumpAndSettle();

    expect(find.text('Perbarui Data Wajah?'), findsOneWidget);
    expect(
      find.text(
        'Wajah yang terdaftar akan diperbarui melalui proses pendaftaran wajah.',
      ),
      findsOneWidget,
    );
    expect(find.text('Batal'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Perbarui'), findsOneWidget);
    expect(find.byKey(_registerStubKey), findsNothing);
  });

  testWidgets('5. Batal tidak membuka Face Register', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: true),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui Data Wajah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.byKey(_registerStubKey), findsNothing);
    expect(find.text('Perbarui Data Wajah?'), findsNothing);
    expect(find.text('Perbarui Data Wajah'), findsOneWidget);
  });

  testWidgets('6. Perbarui membuka existing Face Register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: _FakeFaceService(registered: true),
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui Data Wajah'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Perbarui'));
    await tester.pumpAndSettle();

    expect(find.byKey(_registerStubKey), findsOneWidget);
    expect(find.byType(RegisterFacePage), findsNothing);
  });

  testWidgets('7. halaman refresh setelah kembali dari registration', (
    WidgetTester tester,
  ) async {
    final _FakeFaceService service = _FakeFaceService(registered: false);
    await tester.pumpWidget(
      MaterialApp(
        home: FaceDataPage(
          faceService: service,
          registerFaceBuilder: _stubRegister,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(find.text('Belum terdaftar'), findsOneWidget);

    await tester.tap(find.text('Daftarkan Wajah'));
    await tester.pumpAndSettle();

    service.registered = true;
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('✓ Wajah sudah terdaftar'), findsOneWidget);
    expect(find.text('Perbarui Data Wajah'), findsOneWidget);
    expect(find.text('Daftarkan Wajah'), findsNothing);
  });
}

const Key _registerStubKey = Key('existing-face-register-stub');

Widget _stubRegister(BuildContext context) {
  return Scaffold(
    key: _registerStubKey,
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kembali'),
      ),
    ),
  );
}

class _FakeFaceService extends FaceService {
  _FakeFaceService({required this.registered});

  bool registered;
  int calls = 0;

  @override
  Future<FaceStatus> getStatus() async {
    calls += 1;
    return FaceStatus(isRegistered: registered);
  }
}
