import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'notification_read_ux.dart';

/// State notifikasi di seluruh app. Polling pelan memakai `GET /notifications`.
class NotificationInbox extends ChangeNotifier {
  NotificationInbox({
    NotificationService? service,
    TokenStorage? tokenStorage,
    Future<bool> Function()? isAuthenticated,
    this.pollInterval = const Duration(seconds: 45),
  })  : _service = service ?? NotificationService(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _isAuthenticatedOverride = isAuthenticated;

  final NotificationService _service;
  final TokenStorage _tokenStorage;
  final Future<bool> Function()? _isAuthenticatedOverride;
  final Duration pollInterval;

  List<NotificationModel> _items = <NotificationModel>[];
  final Set<int> _knownIds = <int>{};
  final Set<int> _announcedIds = <int>{};
  final List<NotificationModel> _bannerQueue = <NotificationModel>[];

  bool _fetching = false;
  bool _started = false;
  bool _disposed = false;
  bool _hasSnapshot = false;
  Timer? _poll;

  List<NotificationModel> get items =>
      List<NotificationModel>.unmodifiable(_items);

  int get unreadCount => NotificationReadUx.unreadCount(_items);

  String unreadBadgeLabel({int max = 99}) {
    final int count = unreadCount;
    if (count <= 0) return '';
    if (count > max) return '$max+';
    return '$count';
  }

  NotificationModel? get currentBanner =>
      _bannerQueue.isEmpty ? null : _bannerQueue.first;

  bool get hasBanner => _bannerQueue.isNotEmpty;

  void start() {
    if (_disposed) return;
    if (!_started) {
      _started = true;
      _poll ??= Timer.periodic(pollInterval, (_) {
        unawaited(refresh(silent: true));
      });
    }
    unawaited(refresh(silent: true));
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _started = false;
    clearSession();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _poll = null;
    _started = false;
    super.dispose();
  }

  Future<bool> _hasSession() {
    final Future<bool> Function()? override = _isAuthenticatedOverride;
    if (override != null) return override();
    return _tokenStorage.hasToken();
  }

  Future<void> syncAuth() async {
    if (_disposed) return;
    final bool authed = await _hasSession();
    if (!authed) {
      clearSession();
    }
  }

  Future<void> refresh({bool silent = true}) async {
    if (_disposed) return;
    final bool authed = await _hasSession();
    if (!authed) {
      clearSession();
      return;
    }
    if (NotificationReadUx.skipDuplicateFetch(inFlight: _fetching)) return;
    _fetching = true;
    try {
      final List<NotificationModel> next = await _service.getNotifications();
      if (_disposed) return;
      _applyFetch(next);
    } on ApiException {
      // Poll senyap: sesi 401 ditangani halaman yang sedang dipakai.
    } catch (_) {
      // Poll senyap: data lama tetap.
    } finally {
      _fetching = false;
    }
  }

  void _applyFetch(List<NotificationModel> next) {
    final bool firstSnapshot = !_hasSnapshot;
    _hasSnapshot = true;
    final Set<int> incomingIds = next
        .where((NotificationModel item) => item.id > 0)
        .map((NotificationModel item) => item.id)
        .toSet();

    if (firstSnapshot) {
      _announcedIds.addAll(incomingIds);
    } else {
      final List<NotificationModel> fresh = next
          .where(
            (NotificationModel item) =>
                item.id > 0 &&
                !_knownIds.contains(item.id) &&
                !item.isRead &&
                !_announcedIds.contains(item.id),
          )
          .toList();
      for (final NotificationModel item in fresh) {
        _announcedIds.add(item.id);
        _bannerQueue.add(item);
      }
    }

    _knownIds.addAll(incomingIds);
    _items = List<NotificationModel>.of(next);
    _bannerQueue.removeWhere((NotificationModel banner) {
      final NotificationModel match = _items.firstWhere(
        (NotificationModel item) => item.id == banner.id,
        orElse: () => banner,
      );
      final bool missing =
          !_items.any((NotificationModel item) => item.id == banner.id);
      return missing || match.isRead;
    });
    _notify();
  }

  void replaceAll(List<NotificationModel> next) {
    _applyFetch(next);
  }

  void clearSession() {
    if (_items.isEmpty &&
        _knownIds.isEmpty &&
        _announcedIds.isEmpty &&
        _bannerQueue.isEmpty &&
        !_hasSnapshot) {
      return;
    }
    _items = <NotificationModel>[];
    _knownIds.clear();
    _announcedIds.clear();
    _bannerQueue.clear();
    _hasSnapshot = false;
    _notify();
  }

  void dismissBanner(int id) {
    _bannerQueue.removeWhere((NotificationModel item) => item.id == id);
    _notify();
  }

  Future<bool> markAsRead(int id) async {
    try {
      final NotificationModel updated = await _service.markAsRead(id);
      if (!updated.isRead) return false;
      applyLocalRead(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  void applyLocalRead(NotificationModel updated) {
    if (!updated.isRead) return;
    _items = NotificationReadUx.applyRead(_items, updated);
    _bannerQueue.removeWhere((NotificationModel item) => item.id == updated.id);
    _notify();
  }

  Future<bool> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      await refresh(silent: true);
      _bannerQueue.clear();
      _notify();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Item baru yang sama tidak di-queue dua kali (rebuild/refresh).
  bool alreadyAnnounced(int id) => _announcedIds.contains(id);

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
