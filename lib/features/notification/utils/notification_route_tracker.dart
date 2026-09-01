import 'package:flutter/material.dart';

import 'notification_open.dart';

/// Melacak rute teratas tanpa mengubah stack Navigator.
class NotificationRouteTracker extends NavigatorObserver {
  String? currentName;
  VoidCallback? onRouteChanged;

  bool get isVotOnTop => currentName == NotificationOpen.votRouteName;

  void _remember(Route<dynamic>? route) {
    currentName = route?.settings.name;
    onRouteChanged?.call();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _remember(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(previousRoute);
  }
}
