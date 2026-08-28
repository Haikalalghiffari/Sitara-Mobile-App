import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/login/pages/activate_account_page.dart';
import 'features/login/pages/login_page.dart';
import 'features/login/utils/activation_link.dart';
import 'features/notification/utils/notification_inbox.dart';
import 'features/notification/utils/notification_inbox_scope.dart';
import 'features/notification/utils/notification_route_tracker.dart';
import 'features/notification/widgets/notification_overlay_host.dart';

final GlobalKey<NavigatorState> sitaraNavigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SitaraApp());
}

class SitaraApp extends StatefulWidget {
  const SitaraApp({super.key});

  @override
  State<SitaraApp> createState() => _SitaraAppState();
}

class _SitaraAppState extends State<SitaraApp> {
  final AppLinks _appLinks = AppLinks();
  final NotificationInbox _notificationInbox = NotificationInbox();
  final NotificationRouteTracker _notificationRouteTracker =
      NotificationRouteTracker();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {},
    );
    _notificationRouteTracker.onRouteChanged = () {
      unawaited(_notificationInbox.syncAuth());
    };
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _notificationInbox.dispose();
    super.dispose();
  }

  void _handleIncomingUri(Uri uri) {
    final String? token = ActivationLink.tokenFrom(uri);
    if (token == null) return;

    debugPrint(
      'Activation link diterima token=${ActivationLink.maskToken(token)}',
    );

    void openPage() {
      final NavigatorState? navigator = sitaraNavigatorKey.currentState;
      if (navigator == null) return;

      Route<dynamic>? topRoute;
      navigator.popUntil((Route<dynamic> route) {
        topRoute = route;
        return true;
      });
      if (topRoute?.settings.name == '/activate' &&
          topRoute?.settings.arguments == token) {
        return;
      }

      navigator.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: '/activate', arguments: token),
          builder: (_) => ActivateAccountPage(activationToken: token),
        ),
      );
    }

    if (sitaraNavigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openPage());
      return;
    }

    openPage();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationInboxScope(
      inbox: _notificationInbox,
      child: MaterialApp(
        title: 'SITARA Health',
        navigatorKey: sitaraNavigatorKey,
        navigatorObservers: <NavigatorObserver>[_notificationRouteTracker],
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (BuildContext context, Widget? child) {
          return NotificationOverlayHost(
            inbox: _notificationInbox,
            navigatorKey: sitaraNavigatorKey,
            routeTracker: _notificationRouteTracker,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const LoginPage(),
      ),
    );
  }
}
