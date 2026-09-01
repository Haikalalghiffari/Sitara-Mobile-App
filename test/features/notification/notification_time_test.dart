import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_time.dart';

void main() {
  test('CASE 1: naive timestamp is UTC, then local once', () {
    final DateTime? parsed = NotificationTime.parse('2026-08-28T09:59:34');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc(), DateTime.utc(2026, 8, 28, 9, 59, 34));
    expect(parsed, DateTime.utc(2026, 8, 28, 9, 59, 34).toLocal());
    if (parsed.timeZoneOffset == const Duration(hours: 7)) {
      expect(parsed.hour, 16);
      expect(parsed.minute, 59);
      expect(parsed.second, 34);
    }
  });

  test('CASE 2: Z timestamp is the same instant as naive UTC', () {
    final DateTime? z = NotificationTime.parse('2026-08-28T09:59:34Z');
    final DateTime? naive = NotificationTime.parse('2026-08-28T09:59:34');
    expect(z, isNotNull);
    expect(z!.toUtc(), DateTime.utc(2026, 8, 28, 9, 59, 34));
    expect(z.toUtc(), naive!.toUtc());
  });

  test('CASE 3: +07:00 offset is the same instant', () {
    final DateTime? offset =
        NotificationTime.parse('2026-08-28T16:59:34+07:00');
    final DateTime? naive = NotificationTime.parse('2026-08-28T09:59:34');
    expect(offset, isNotNull);
    expect(offset!.toUtc(), DateTime.utc(2026, 8, 28, 9, 59, 34));
    expect(offset.toUtc(), naive!.toUtc());
    expect(offset.toUtc().hour, isNot(16));
  });

  test('CASE 4: 10 seconds ago is baru saja', () {
    final DateTime created = DateTime.utc(2026, 8, 28, 9, 59, 34).toLocal();
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(seconds: 10)),
      ),
      'baru saja',
    );
  });

  test('CASE 5: 70 seconds ago is 1 menit yang lalu', () {
    final DateTime created = DateTime.utc(2026, 8, 28, 9, 59, 34).toLocal();
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(seconds: 70)),
      ),
      '1 menit yang lalu',
    );
  });

  test('CASE 6: 2 hours ago', () {
    final DateTime created = DateTime.utc(2026, 8, 28, 9, 59, 34).toLocal();
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(hours: 2)),
      ),
      '2 jam yang lalu',
    );
  });

  test('CASE 7: 1 day ago', () {
    final DateTime created = DateTime.utc(2026, 8, 27, 9, 59, 34).toLocal();
    expect(
      NotificationTime.relative(
        created,
        now: created.add(const Duration(days: 1)),
      ),
      '1 hari yang lalu',
    );
  });

  test('CASE 8: naive UTC does not become 7 jam yang lalu', () {
    final DateTime? created = NotificationTime.parse('2026-08-28T09:59:34');
    final DateTime now = DateTime.utc(2026, 8, 28, 9, 59, 44).toLocal();
    expect(created, isNotNull);
    expect(NotificationTime.relative(created, now: now), 'baru saja');
    expect(
      NotificationTime.relative(created, now: now),
      isNot('7 jam yang lalu'),
    );
  });

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

  test('future timestamp is baru saja, not negative minutes', () {
    final DateTime created = DateTime(2026, 8, 28, 16, 0);
    expect(
      NotificationTime.relative(
        created,
        now: created.subtract(const Duration(minutes: 1)),
      ),
      'baru saja',
    );
    expect(
      NotificationTime.relative(
        created,
        now: created.subtract(const Duration(minutes: 1)),
      ),
      isNot(contains('-')),
    );
  });

  test('UTC +00:00 is the same instant as Z', () {
    final DateTime? zero = NotificationTime.parse('2026-08-28T09:59:34+00:00');
    expect(zero!.toUtc(), DateTime.utc(2026, 8, 28, 9, 59, 34));
  });

  test('space-separated naive UTC is still UTC', () {
    final DateTime? parsed =
        NotificationTime.parse('2026-08-28 09:59:34.123');
    expect(parsed!.toUtc(), DateTime.utc(2026, 8, 28, 9, 59, 34, 123));
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

  test('label follows created_at UTC, not page-open wall clock', () {
    final NotificationModel item = NotificationModel.fromJson(
      <String, dynamic>{
        'id': 3,
        'user_id': 8,
        'title': 'Judul',
        'message': 'Isi',
        'type': 'medicine',
        'is_read': false,
        'is_active': true,
        'created_at': '2026-08-28T09:00:00',
        'updated_at': '2026-08-28T09:00:00',
      },
    );
    expect(
      NotificationTime.labelFor(
        item,
        now: DateTime.utc(2026, 8, 28, 9, 5).toLocal(),
      ),
      '5 menit yang lalu',
    );
    expect(
      NotificationTime.labelFor(
        item,
        now: DateTime.utc(2026, 8, 28, 10, 0).toLocal(),
      ),
      '1 jam yang lalu',
    );
    expect(
      NotificationTime.labelFor(
        item,
        now: DateTime.utc(2026, 8, 28, 9, 0, 10).toLocal(),
      ),
      isNot('7 jam yang lalu'),
    );
  });
}
