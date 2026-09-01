import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_filter.dart';
import 'package:sitara/features/notification/utils/notification_tap.dart';
import 'package:sitara/features/notification/widgets/notification_card.dart';
import 'package:sitara/features/report/models/complaint.dart';

NotificationModel _item({
  required String type,
  int? referenceId,
  String? referenceType,
  String title = 'Judul',
  String message = 'Isi',
  bool isRead = false,
}) {
  return NotificationModel(
    id: 1,
    userId: 8,
    title: title,
    message: message,
    type: type,
    referenceType: referenceType,
    referenceId: referenceId,
    isRead: isRead,
    isActive: true,
    createdAt: '2026-08-26T10:00:00',
    updatedAt: '2026-08-26T10:00:00',
  );
}

void main() {
  test('complaint notification parses type and reference_id as complaint_id', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 11,
        'user_id': 8,
        'title': 'Balasan keluhan',
        'message': 'Petugas telah membalas keluhan Anda.',
        'type': 'complaint',
        'reference_type': null,
        'reference_id': 42,
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-26T10:00:00',
        'updated_at': '2026-08-26T10:00:00',
      },
    );

    expect(item.isComplaintNotification, isTrue);
    expect(item.referenceId, 42);
    expect(NotificationTap.complaintId(item), 42);
    expect(
      NotificationTap.targetOf(item),
      NotificationOpenTarget.complaintHistory,
    );
    expect(NotificationCategoryFilter.complaint.matches(item), isTrue);
  });

  test('complaint tap uses complaint_id from reference_id', () {
    final NotificationModel item = _item(type: 'complaint', referenceId: 7);
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.complaintId(item), 7);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(
      NotificationTap.targetOf(item),
      NotificationOpenTarget.complaintHistory,
    );
  });

  test('complaint without reference_id still opens history, not a fake id', () {
    final NotificationModel item = _item(type: 'complaint');
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.complaintId(item), isNull);
  });

  test('video notification parses reference_id as daily_medication_id', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 12,
        'user_id': 8,
        'title': 'Verifikasi minum obat',
        'message': 'Verifikasi minum obat berhasil.',
        'type': 'video',
        'reference_type': null,
        'reference_id': 19,
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-26T10:00:00',
        'updated_at': '2026-08-26T10:00:00',
      },
    );

    expect(item.isVideoNotification, isTrue);
    expect(item.referenceType, isNull);
    expect(NotificationTap.dailyMedicationId(item), 19);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.votSession);
    expect(NotificationCategoryFilter.all.matches(item), isTrue);
    expect(NotificationCategoryFilter.medicine.matches(item), isFalse);
    expect(NotificationCategoryFilter.complaint.matches(item), isFalse);
  });

  test('video tap does not start a new VOT session', () {
    final NotificationModel item = _item(type: 'video', referenceId: 19);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.opensVot(item), isTrue);
    expect(ApiEndpoints.votSession(19), '/vot/19');
    expect(ApiEndpoints.votSession(19), isNot(ApiEndpoints.votStart));
  });

  test('video without reference_id is marked readable but not navigated', () {
    final NotificationModel item = _item(type: 'video');
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.shouldNavigate(item), isFalse);
    expect(NotificationTap.dailyMedicationId(item), isNull);
  });

  test('refill type stays in Obat and opens refill history', () {
    final NotificationModel item = _item(type: 'refill', referenceId: 5);
    expect(NotificationCategoryFilter.medicine.matches(item), isTrue);
    expect(
      NotificationTap.targetOf(item),
      NotificationOpenTarget.refillHistory,
    );
    expect(NotificationTap.refillId(item), 5);
    expect(NotificationTap.opensVot(item), isFalse);
  });

  test('control type still opens medicine control highlight', () {
    final NotificationModel item = _item(type: 'control', referenceId: 8);
    expect(
      NotificationTap.targetOf(item),
      NotificationOpenTarget.controlSchedule,
    );
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(NotificationTap.dailyMedicationId(item), isNull);
  });

  test('medicine reminder opens Home, not AI-VOT', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 21,
        'user_id': 8,
        'title': 'Pengingat minum obat',
        'message': 'Sudah waktunya minum obat.',
        'type': 'medicine',
        'reference_type': null,
        'reference_id': 19,
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-26T10:00:00',
        'updated_at': '2026-08-26T10:00:00',
      },
    );

    expect(item.isMedicineNotification, isTrue);
    expect(item.message, 'Sudah waktunya minum obat.');
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.home);
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.dailyMedicationId(item), isNull);
    expect(NotificationTap.complaintId(item), isNull);
    expect(NotificationTap.refillId(item), isNull);
    expect(ApiEndpoints.notificationRead(item.id), '/notifications/21/read');
    expect(ApiEndpoints.votSession(19), isNot(ApiEndpoints.notificationRead(21)));
  });

  test('medicine tap ignores reference_id and does not start VOT', () {
    final NotificationModel item = _item(type: 'medicine', referenceId: 99);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.home);
    expect(NotificationTap.dailyMedicationId(item), isNull);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(ApiEndpoints.votStart, '/vot/start');
    expect(ApiEndpoints.votSession(99), '/vot/99');
  });

  test('medicine double destination is a single Home action', () {
    final NotificationModel item = _item(type: 'medicine', referenceId: 3);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.home);
    expect(NotificationTap.targetOf(item), isNot(NotificationOpenTarget.votSession));
    expect(
      <NotificationOpenTarget>{
        NotificationTap.targetOf(item),
        NotificationTap.targetOf(item),
      },
      <NotificationOpenTarget>{NotificationOpenTarget.home},
    );
  });

  test('complaint lookup uses GET /complaints/my list, not GET /complaints/{id}', () {
    expect(ApiEndpoints.myComplaints, '/complaints/my');
    expect(ApiEndpoints.myComplaints.contains('{id}'), isFalse);

    final List<Complaint> mine = <Complaint>[
      Complaint(
        id: 42,
        treatmentId: 1,
        handledBy: 2,
        category: 'Mual / Muntah',
        description: 'Mual setelah minum obat',
        status: 'in_progress',
        response: 'Silakan istirahat.',
        isActive: true,
        createdAt: '2026-08-26T10:00:00',
        updatedAt: '2026-08-26T11:00:00',
      ),
    ];

    expect(Complaint.findById(mine, 42)?.id, 42);
    expect(Complaint.findById(mine, 99), isNull);
    expect(Complaint.findById(mine, null), isNull);
  });

  testWidgets('medicine reminder card is displayed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationCard(
            icon: Icons.medication,
            iconBackground: Colors.teal,
            title: 'Pengingat minum obat',
            subtitle: 'Sudah waktunya minum obat.',
            time: '10:00',
          ),
        ),
      ),
    );

    expect(find.text('Sudah waktunya minum obat.'), findsOneWidget);
    expect(find.text('Pengingat minum obat'), findsOneWidget);
  });
}
