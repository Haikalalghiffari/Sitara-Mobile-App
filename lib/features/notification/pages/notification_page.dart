import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../../core/network/api_exception.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../../home/pages/home_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

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
  static const String _allFilter = "Semua";

  /// Label pada pill filter dipetakan ke nilai `type` yang benar-benar dipakai
  /// backend (`NotificationType`). Nilai null berarti tanpa penyaringan.
  ///
  /// Kategori "Pesan" dan "Progres" pada desain awal tidak dipertahankan karena
  /// backend tidak memiliki tipe notifikasi yang setara, sehingga pill-nya tidak
  /// akan pernah cocok dengan data apa pun.
  static const Map<String, String?> _filters = <String, String?>{
    _allFilter: null,
    "Obat": "medicine",
    "Kontrol": "control",
    "Keluhan": "complaint",
    "Refill": "refill",
    "Verifikasi": "video",
  };

  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  List<NotificationModel> _notifications = <NotificationModel>[];
  String _selectedFilter = _allFilter;

  bool _isLoading = true;

  /// Menahan aksi tulis agar tidak ada dua permintaan yang saling menimpa.
  bool _isBusy = false;

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
    setState(() {
      if (!silent) _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int userId = _userId ?? (await _authService.getProfile()).id;

      final List<NotificationModel> notifications =
          await _notificationService.getNotifications();

      if (!mounted) return;

      // Backend seharusnya hanya mengirim notifikasi milik pemegang token.
      // Bila ternyata ada milik pengguna lain, daftar tidak ditampilkan sama
      // sekali: menyaringnya di aplikasi akan menutupi masalah kebocoran data
      // di server.
      if (notifications.any((item) => item.userId != userId)) {
        setState(() {
          _isLoading = false;
          _notifications = <NotificationModel>[];
          _errorMessage = "Notifikasi tidak dapat ditampilkan karena server "
              "mengirim data milik pengguna lain.";
        });
        return;
      }

      setState(() {
        _userId = userId;
        _notifications = _sortedByNewest(notifications);
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = ApiException.unexpectedMessage;
      });
    }
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
    final String? type = _filters[_selectedFilter];
    if (type == null) return _notifications;

    return _notifications.where((item) => item.type == type).toList();
  }

  void _selectFilter(String filter) {
    if (filter == _selectedFilter) return;
    setState(() => _selectedFilter = filter);
  }

  /// `PUT /notifications/{id}/read` saat kartunya ditekan.
  Future<void> _markAsRead(NotificationModel item) async {
    if (item.isRead || _isBusy) return;

    setState(() => _isBusy = true);

    try {
      final NotificationModel updated =
          await _notificationService.markAsRead(item.id);

      if (!mounted) return;

      setState(() {
        _notifications = _notifications
            .map((current) => current.id == updated.id ? updated : current)
            .toList();
      });
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

  /// `PUT /notifications/read-all`, berlaku untuk seluruh notifikasi milik
  /// pengguna, bukan hanya kategori yang sedang tampil.
  Future<void> _markAllAsRead() async {
    if (_isBusy) return;

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
    if (_isBusy || _notifications.isEmpty) return;

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
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        NotificationEmpty(
          icon: Icons.cloud_off_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.errorContainer,
          title: "Gagal memuat notifikasi",
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
              : "Tidak ada notifikasi pada kategori $_selectedFilter.",
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
          onTap: () => _markAsRead(item),
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
                              ),

                              const SizedBox(height: 24),

                              NotificationFilterTabs(
                                filters: _filters.keys.toList(),
                                selected: _selectedFilter,
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
