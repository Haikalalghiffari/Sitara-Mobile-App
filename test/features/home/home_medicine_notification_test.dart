import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_tap.dart';

void main() {
  test('medicine reminder from notification opens Home, not AI-VOT', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 21,
        'user_id': 8,
        'title': 'Pengingat minum obat',
        'message': 'Jadwal minum obat Anda sudah tiba.',
        'type': 'medicine',
        'reference_id': 19,
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-28T16:25:00+07:00',
        'updated_at': '2026-08-28T16:25:00+07:00',
      },
    );

    expect(NotificationTap.targetOf(item), NotificationOpenTarget.home);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.dailyMedicationId(item), isNull);
    expect(ApiEndpoints.votStart, '/vot/start');
    expect(ApiEndpoints.votSession(19), isNot(ApiEndpoints.notificationRead(21)));
  });
}
