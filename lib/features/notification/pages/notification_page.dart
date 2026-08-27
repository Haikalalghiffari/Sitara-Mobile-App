import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../../core/network/api_exception.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../../home/pages/home_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../medicine/pages/medicine_refill_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../report/pages/report_page.dart';
import '../../ai_vot/pages/ai_vot_page.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/notification_filter.dart';
import '../utils/notification_read_ux.dart';
import '../utils/notification_tap.dart';

import '../widgets/notification_header.dart';
import '../widgets/notification_filter_tabs.dart';
import '../widgets/notification_section_title.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty.dart';

/// Daftar notifikasi diambil dari `GET /notifications`.
///
/// Backend menyediakan penandaan sudah dibaca (satu dan seluruhnya) serta
/// penghapusan per notifikasi. Tidak ada endpoint penghapusan massal, sehingga
/// "Hapus semua" dijalankan sebagai serangkaian permintaan hapus satu per satu.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  List<NotificationModel> _notifications = <NotificationModel>[];
  NotificationCategoryFilter _selectedFilter = NotificationCategoryFilter.all;

  bool _isLoading = true;
  bool _isBusy = false;
  /// Terpisah dari [_isLoading]: flag UI mulai `true` agar spinner tampil
  /// pada frame pertama, tetapi tidak boleh memblokir fetch awal.
  bool _isFetching = false;
  final NotificationReadLock _readLock = NotificationReadLock();

  String? _errorMessage;

  /// Id pengguna dari `GET /auth/profile`, disimpan agar tidak diminta ulang
  /// setiap kali daftar dimuat.
  int? _userId;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _load();
  }

  /// Memuat daftar notifikasi dari backend.
  ///
  /// [silent] dipakai oleh pull-to-refresh dan penyegaran setelah aksi tulis,
  /// karena indikatornya sudah ditampilkan di tempat lain.
  Future<void> _load({bool silent = false}) async {
    if (NotificationReadUx.skipDuplicateFetch(inFlight: _isFetching)) {
      return;
    }
    _isFetching = true;

    // Jangan setState di sini pada fetch awal: [_isLoading] sudah true dari
    // initState, dan setState sinkron sebelum await tidak diizinkan.
    if (!silent && !_isLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      debugPrint('[Notification] fetch start');

      final int userId = _userId ?? (await _authService.getProfile()).id;

      debugPrint('[Notification] GET /notifications');
      final List<NotificationModel> notifications =
          await _notificationService.getNotifications();
      debugPrint('[Notification] response received');

      if (!mounted) return;

      if (notifications.any((item) => item.userId != userId)) {
        setState(() {
          if (_notifications.isEmpty) {
            _errorMessage = "Notifikasi tidak dapat ditampilkan karena server "
                "mengirim data milik pengguna lain.";
          }
        });
        if (_notifications.isNotEmpty) {
          _showMessage(
            "Notifikasi tidak dapat ditampilkan karena server "
            "mengirim data milik pengguna lain.",
          );
        }
        return;
      }

      setState(() {
        _userId = userId;
        _notifications = _sortedByNewest(notifications);
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      debugPrint('[Notification] error');
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      _handleLoadFailure(error.message, silent: silent);
    } catch (_) {
      debugPrint('[Notification] error');
      if (!mounted) return;
      _handleLoadFailure(ApiException.unexpectedMessage, silent: silent);
    } finally {
      _isFetching = false;
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLoadFailure(String message, {required bool silent}) {
    if (NotificationReadUx.keepExistingOnError(
      silent: silent,
      existing: _notifications,
    )) {
      _showMessage(message);
      return;
    }

    setState(() => _errorMessage = message);
  }

  /// Urutan dari backend tidak dijamin, sedangkan halaman ini memisahkan
  /// notifikasi hari ini dan sebelumnya.
  List<NotificationModel> _sortedByNewest(List<NotificationModel> items) {
    final List<NotificationModel> sorted = List<NotificationModel>.of(items);

    sorted.sort((a, b) {
      final DateTime? left = a.createdAtDateTime;
      final DateTime? right = b.createdAtDateTime;

      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;

      return right.compareTo(left);
    });

    return sorted;
  }

  List<NotificationModel> get _visibleNotifications {
    return _notifications.where(_selectedFilter.matches).toList();
  }

  void _selectFilter(String label) {
    final NotificationCategoryFilter? filter =
        NotificationCategoryFilter.fromLabel(label);
    if (filter == null || filter == _selectedFilter) return;
    setState(() => _selectedFilter = filter);
  }

  bool _isNavigatingFromTap = false;

  /// `PUT /notifications/{id}/read` saat kartunya ditekan, lalu membuka
  /// halaman existing yang sesuai `type` dan `reference_id`.
  ///
  /// Notifikasi tidak dihapus. Bila sudah dibaca, permintaan baca dilewati
  /// dan navigasi tetap dijalankan. Tap `medicine` ke Home, bukan AI-VOT.
  /// Tap `video` tidak memanggil `POST /vot/start`.
  Future<void> _handleNotificationTap(NotificationModel item) async {
    if (_readLock.isMarking(item.id) || _isBusy || _isNavigatingFromTap) {
      return;
    }

    if (!item.isRead) {
      final bool marked = await _markAsRead(item);
      if (!mounted || !marked) return;
    }

    if (!NotificationTap.shouldNavigate(item)) return;
    if (_isNavigatingFromTap) return;

    switch (NotificationTap.targetOf(item)) {
      case NotificationOpenTarget.home:
        _isNavigatingFromTap = true;
        _openMainPage(0);
        return;
      case NotificationOpenTarget.controlSchedule:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MedicinePage(
              highlightedControlScheduleId: item.referenceId,
            ),
          ),
        );
        return;
      case NotificationOpenTarget.complaintHistory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPage(
              highlightedComplaintId: NotificationTap.complaintId(item),
            ),
          ),
        );
        return;
      case NotificationOpenTarget.refillHistory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineRefillPage(
              highlightedRefillId: NotificationTap.refillId(item),
            ),
          ),
        );
        return;
      case NotificationOpenTarget.votSession:
        if (NotificationTap.startsNewVotSession(item)) return;
        final int? dailyMedicationId = NotificationTap.dailyMedicationId(item);
        if (dailyMedicationId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiVotPage(
              resumeDailyMedicationId: dailyMedicationId,
            ),
          ),
        );
        return;
      case NotificationOpenTarget.none:
        return;
    }
  }

  Future<bool> _markAsRead(NotificationModel item) async {
    if (item.isRead) return true;
    if (!_readLock.tryBegin(item.id)) return false;

    setState(() {});

    try {
      final NotificationModel updated =
          await _notificationService.markAsRead(item.id);

      if (!mounted) return false;

      if (!updated.isRead) {
        _showMessage("Notifikasi belum ditandai sudah dibaca. Silakan coba lagi.");
        return false;
      }

      setState(() {
        _notifications = NotificationReadUx.applyRead(_notifications, updated);
      });
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return false;
      }

      _showMessage(error.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      _showMessage(ApiException.unexpectedMessage);
      return false;
    } finally {
      _readLock.end(item.id);
      if (mounted) setState(() {});
    }
  }

  /// `PUT /notifications/read-all`, berlaku untuk seluruh notifikasi milik
  /// pengguna, bukan hanya kategori yang sedang tampil.
  Future<void> _markAllAsRead() async {
    if (_isBusy || _readLock.isBusy) return;

    if (!_notifications.any((item) => !item.isRead)) {
      _showMessage("Tidak ada notifikasi yang belum dibaca.");
      return;
    }

    setState(() => _isBusy = true);

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      // Balasan endpoint ini berupa daftar, tetapi tidak ada jaminan isinya
      // seluruh notifikasi pengguna atau hanya yang baru saja diperbarui.
      // Karena itu daftar diambil ulang agar tampilan mengikuti server.
      await _load(silent: true);

      if (!mounted) return;
      _showMessage("Semua notifikasi ditandai sudah dibaca.");
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(ApiException.unexpectedMessage);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Menghapus seluruh notifikasi pengguna.
  ///
  /// Backend tidak memiliki endpoint hapus massal, jadi setiap notifikasi
  /// dihapus lewat `DELETE /notifications/{id}` satu per satu. Kegagalan
  /// sebagian mungkin terjadi, sehingga jumlah yang benar-benar terhapus
  /// dilaporkan apa adanya.
  Future<void> _confirmDeleteAll() async {
    if (_isBusy || _readLock.isBusy || _notifications.isEmpty) return;

    final bool confirmed = await _askDeleteConfirmation() ?? false;
    if (!confirmed || !mounted) return;

    final List<int> ids = _notifications.map((item) => item.id).toList();

    setState(() => _isBusy = true);

    int deleted = 0;
    bool sessionExpired = false;
    String? failureMessage;

    for (final int id in ids) {
      try {
        await _notificationService.delete(id);
        deleted++;
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          sessionExpired = true;
          break;
        }
        failureMessage ??= error.message;
      } catch (_) {
        failureMessage ??= ApiException.unexpectedMessage;
      }
    }

    if (!mounted) return;

    if (sessionExpired) {
      await _handleExpiredSession();
      return;
    }

    await _load(silent: true);

    if (!mounted) return;

    setState(() => _isBusy = false);

    if (deleted == ids.length) {
      _showMessage("Semua notifikasi dihapus.");
    } else {
      _showMessage(
        "$deleted dari ${ids.length} notifikasi berhasil dihapus. "
        "${failureMessage ?? ''}".trim(),
      );
    }
  }

  Future<bool?> _askDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Hapus semua notifikasi?"),
          content: const Text(
            "Seluruh notifikasi Anda akan dihapus dari server dan tidak "
            "dapat dikembalikan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Batal"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Memakai [AuthService.logout] yang sudah ada agar tidak ada mekanisme
  /// pembersihan token baru.
  Future<void> _handleExpiredSession() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _openMainPage(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProgressPage(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MedicinePage(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
        break;
    }
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: AppSpacing.md),
                Text("Memuat data..."),
              ],
            ),
          ),
        ),
      ];
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return [
        NotificationEmpty(
          icon: Icons.cloud_off_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.errorContainer,
          title: "Gagal memuat notifikasi.",
          message: _errorMessage!,
          actionLabel: "Coba Lagi",
          onAction: _load,
        ),
      ];
    }

    return _buildNotificationList();
  }

  List<Widget> _buildNotificationList() {
    final List<NotificationModel> visible = _visibleNotifications;

    if (visible.isEmpty) {
      return [
        NotificationEmpty(
          message: _notifications.isEmpty
              ? "Semua aktivitas terbaru akan muncul di sini setelah tersedia."
              : "Tidak ada notifikasi pada kategori ${_selectedFilter.label}.",
        ),
      ];
    }

    final List<NotificationModel> recent =
        visible.where(_isFromToday).toList();
    final List<NotificationModel> earlier =
        visible.where((item) => !_isFromToday(item)).toList();

    final bool hasUnread = visible.any((item) => !item.isRead);

    return [
      if (recent.isNotEmpty) ...[
        NotificationSectionTitle(
          title: "Terbaru",
          actionText: hasUnread ? "Tandai sudah dibaca" : null,
          onAction: _markAllAsRead,
        ),

        const SizedBox(height: 16),

        ..._buildCards(recent),
      ],

      if (recent.isNotEmpty && earlier.isNotEmpty) const SizedBox(height: 30),

      if (earlier.isNotEmpty) ...[
        NotificationSectionTitle(
          title: "Sebelumnya",
          // Aksi hanya pindah ke sini bila tidak ada bagian "Terbaru".
          actionText: recent.isEmpty && hasUnread ? "Tandai sudah dibaca" : null,
          onAction: _markAllAsRead,
        ),

        const SizedBox(height: 18),

        ..._buildCards(earlier),
      ],
    ];
  }

  List<Widget> _buildCards(List<NotificationModel> items) {
    final List<Widget> cards = [];

    for (int index = 0; index < items.length; index++) {
      if (index > 0) cards.add(const SizedBox(height: 18));

      final NotificationModel item = items[index];

      cards.add(
        NotificationCard(
          icon: _iconFor(item.type),
          iconBackground: _colorFor(item.type),
          title: item.title,
          subtitle: item.message,
          time: _timeLabel(item),
          isRead: item.isRead,
          onTap: _readLock.isMarking(item.id) || _isBusy || _isNavigatingFromTap
              ? null
              : () => _handleNotificationTap(item),
        ),
      );
    }

    return cards;
  }

  IconData _iconFor(String type) {
    return switch (type) {
      "medicine" => Icons.medication,
      "control" => Icons.event_available_rounded,
      "complaint" => Icons.chat_bubble,
      "refill" => Icons.inventory_2_rounded,
      "video" => Icons.videocam_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorFor(String type) {
    return switch (type) {
      "medicine" => AppColors.primary,
      "control" => AppColors.secondary,
      "complaint" => AppColors.warning,
      "refill" => AppColors.tertiary,
      "video" => AppColors.info,
      _ => AppColors.textSecondary,
    };
  }

  bool _isFromToday(NotificationModel item) {
    final DateTime? created = item.createdAtDateTime;
    if (created == null) return false;

    final DateTime now = DateTime.now();

    return created.year == now.year &&
        created.month == now.month &&
        created.day == now.day;
  }

  /// Mengubah `created_at` menjadi keterangan waktu yang mudah dibaca.
  String _timeLabel(NotificationModel item) {
    final DateTime? created = item.createdAtDateTime;
    if (created == null) return "";

    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(created);

    if (elapsed.isNegative) return _clock(created);
    if (elapsed.inMinutes < 1) return "Baru saja";
    if (elapsed.inMinutes < 60) return "${elapsed.inMinutes} mnt lalu";

    final int dayGap = DateTime(now.year, now.month, now.day)
        .difference(DateTime(created.year, created.month, created.day))
        .inDays;

    if (dayGap == 0) return "${elapsed.inHours} jam lalu";
    if (dayGap == 1) return "Kemarin, ${_clock(created)}";
    if (dayGap < 7) return "$dayGap hari lalu";

    return "${created.day}/${created.month}/${created.year}";
  }

  String _clock(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return "$hour.$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.contentMaxWidth,
                      ),
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => _load(silent: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              NotificationHeader(
                                onMarkAllRead: _markAllAsRead,
                                onDeleteAll: _confirmDeleteAll,
                                isMenuEnabled:
                                    _notifications.isNotEmpty && !_isBusy,
                                unreadCount: NotificationReadUx.unreadCount(
                                  _notifications,
                                ),
                              ),

                              const SizedBox(height: 24),

                              NotificationFilterTabs(
                                filters: NotificationCategoryFilter.labels,
                                selected: _selectedFilter.label,
                                onSelected: _selectFilter,
                              ),

                              const SizedBox(height: 28),

                              ..._buildContent(),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SitaraBottomNavBar(
              // Halaman ini bukan tab kelima. Home dipakai sebagai penanda
              // karena NotificationPage dibuka dari app bar.
              currentIndex: 0,
              onTap: _openMainPage,
            ),
          ],
        ),
      ),
    );
  }
}
