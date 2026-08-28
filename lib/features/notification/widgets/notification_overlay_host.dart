import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../utils/notification_inbox.dart';
import '../utils/notification_open.dart';
import '../utils/notification_route_tracker.dart';
import '../utils/notification_tap.dart';
import 'notification_banner.dart';

/// Overlay banner di atas Navigator. Tidak membuat route baru.
class NotificationOverlayHost extends StatefulWidget {
  const NotificationOverlayHost({
    super.key,
    required this.inbox,
    required this.navigatorKey,
    required this.routeTracker,
    required this.child,
  });

  final NotificationInbox inbox;
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationRouteTracker routeTracker;
  final Widget child;

  @override
  State<NotificationOverlayHost> createState() =>
      _NotificationOverlayHostState();
}

class _NotificationOverlayHostState extends State<NotificationOverlayHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.inbox.addListener(_onInbox);
    widget.inbox.start();
  }

  @override
  void dispose() {
    widget.inbox.removeListener(_onInbox);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.inbox.start();
    }
  }

  void _onInbox() {
    if (mounted) setState(() {});
  }

  Future<void> _onBannerTap(NotificationModel item) async {
    widget.inbox.dismissBanner(item.id);
    if (!item.isRead) {
      await widget.inbox.markAsRead(item.id);
    }
    if (widget.routeTracker.isVotOnTop) return;
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    if (NotificationOpen.isVotOnTop(navigator)) return;
    final BuildContext? navContext = widget.navigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;
    if (!NotificationTap.shouldNavigate(item)) return;
    NotificationOpen.go(navContext, item);
  }

  @override
  Widget build(BuildContext context) {
    final NotificationModel? banner = widget.inbox.currentBanner;

    return Stack(
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: NotificationBanner(
                  item: banner,
                  onTap: () => _onBannerTap(banner),
                  onDismiss: () => widget.inbox.dismissBanner(banner.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
