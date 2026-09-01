import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_filter.dart';

NotificationModel _item({
  required String type,
  String title = 'Judul',
  String message = 'Isi',
}) {
  return NotificationModel(
    id: 1,
    userId: 8,
    title: title,
    message: message,
    type: type,
    referenceType: null,
    referenceId: null,
    isRead: false,
    isActive: true,
    createdAt: '2026-08-26T10:00:00',
    updatedAt: '2026-08-26T10:00:00',
  );
}

void main() {
  final List<NotificationModel> items = <NotificationModel>[
    _item(type: 'medicine', title: 'Jadwal obat'),
    _item(type: 'refill', title: 'Permintaan refill'),
    _item(type: 'control', title: 'Kontrol klinik'),
    _item(type: 'complaint', title: 'Keluhan diterima'),
    _item(type: 'video', title: 'Verifikasi minum'),
    _item(
      type: 'complaint',
      title: 'Obat habis',
      message: 'Perlu refill segera',
    ),
  ];

  List<NotificationModel> visible(NotificationCategoryFilter filter) {
    return items.where(filter.matches).toList();
  }

  test('Semua menampilkan semua notification termasuk video', () {
    expect(visible(NotificationCategoryFilter.all), hasLength(items.length));
  });

  test('filter Obat memakai type medicine dan refill, bukan teks judul', () {
    final List<NotificationModel> obat =
        visible(NotificationCategoryFilter.medicine);

    expect(obat.map((e) => e.type), <String>['medicine', 'refill']);
    expect(
      obat.any((item) => item.title.contains('Obat habis')),
      isFalse,
    );
  });

  test('filter Kontrol hanya type control', () {
    expect(
      visible(NotificationCategoryFilter.control).map((e) => e.type),
      <String>['control'],
    );
  });

  test('filter Keluhan hanya type complaint', () {
    expect(
      visible(NotificationCategoryFilter.complaint)
          .every((item) => item.type == 'complaint'),
      isTrue,
    );
    expect(visible(NotificationCategoryFilter.complaint), hasLength(2));
  });

  test('refill tetap muncul di Semua dan Obat', () {
    expect(
      NotificationCategoryFilter.all.matches(_item(type: 'refill')),
      isTrue,
    );
    expect(
      NotificationCategoryFilter.medicine.matches(_item(type: 'REFILL')),
      isTrue,
    );
    expect(
      NotificationCategoryFilter.control.matches(_item(type: 'refill')),
      isFalse,
    );
  });

  test('daftar kosong tidak membuat filter gagal', () {
    expect(
      <NotificationModel>[]
          .where(NotificationCategoryFilter.medicine.matches)
          .toList(),
      isEmpty,
    );
  });

  test('pill filter hanya Semua Obat Kontrol Keluhan', () {
    expect(
      NotificationCategoryFilter.labels,
      <String>['Semua', 'Obat', 'Kontrol', 'Keluhan'],
    );
  });

  test('Sudah waktunya minum obat stays in Obat by type medicine', () {
    final NotificationModel item = _item(
      type: 'medicine',
      title: 'Pengingat minum obat',
      message: 'Sudah waktunya minum obat.',
    );
    expect(NotificationCategoryFilter.medicine.matches(item), isTrue);
    expect(NotificationCategoryFilter.all.matches(item), isTrue);
    expect(NotificationCategoryFilter.control.matches(item), isFalse);
    expect(NotificationCategoryFilter.complaint.matches(item), isFalse);
  });
}
