import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_time.dart';

void main() {
  test('relative time 1 minute', () {
    final DateTime created = DateTime(2026, 8, 28, 16, 0);
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(minutes: 1)),
      ),
      '1 menit yang lalu',
    );
  });

  test('relative time 1 hour', () {
    final DateTime created = DateTime(2026, 8, 28, 15, 0);
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(hours: 1)),
      ),
      '1 jam yang lalu',
    );
  });

  test('relative time 1 day', () {
    final DateTime created = DateTime(2026, 8, 27, 16, 0);
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(days: 1)),
      ),
      '1 hari yang lalu',
    );
  });

  test('relative time under one minute is baru saja', () {
    final DateTime created = DateTime(2026, 8, 28, 16, 25);
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(seconds: 20)),
      ),
      'baru saja',
    );
  });

  test('timezone offset is converted to local only once', () {
    final DateTime? parsed =
        NotificationTime.parse('2026-08-28T16:25:00+07:00');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc(), DateTime.utc(2026, 8, 28, 9, 25));
    expect(parsed.toUtc().hour, isNot(16));
    expect(parsed.toUtc().hour, isNot(2));
  });

  test('UTC timestamp converts to local once', () {
    final DateTime? parsed = NotificationTime.parse('2026-08-28T09:25:00Z');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc(), DateTime.utc(2026, 8, 28, 9, 25));
  });

  test('naive timestamp is kept as local wall clock', () {
    final DateTime? parsed = NotificationTime.parse('2026-08-28T16:25:00');
    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isFalse);
    expect(parsed.hour, 16);
    expect(parsed.minute, 25);
  });

  test('null and invalid timestamps do not invent a time', () {
    expect(NotificationTime.parse(''), isNull);
    expect(NotificationTime.parse('bukan-tanggal'), isNull);
    expect(NotificationTime.relative(null), isEmpty);
    expect(
      NotificationModel.fromJson(<String, dynamic>{
        'id': 1,
        'user_id': 8,
        'title': 'Judul',
        'message': 'Isi',
        'type': 'medicine',
        'is_read': false,
        'is_active': true,
        'created_at': '',
        'updated_at': '',
      }).createdAtDateTime,
      isNull,
    );
  });

  test('label follows created_at, not page-open time', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 3,
        'user_id': 8,
        'title': 'Judul',
        'message': 'Isi',
        'type': 'medicine',
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-28T16:00:00',
        'updated_at': '2026-08-28T16:00:00',
      },
    );
    expect(
      NotificationTime.labelFor(
        item,
        now: DateTime(2026, 8, 28, 16, 5),
      ),
      '5 menit yang lalu',
    );
    expect(
      NotificationTime.labelFor(
        item,
        now: DateTime(2026, 8, 28, 17, 0),
      ),
      '1 jam yang lalu',
    );
  });
}
