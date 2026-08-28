import 'package:flutter/material.dart';

import '../../ai_vot/pages/ai_vot_page.dart';
import '../../home/pages/home_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../medicine/pages/medicine_refill_page.dart';
import '../../report/pages/report_page.dart';
import '../models/notification_model.dart';
import 'notification_tap.dart';

/// Navigasi tap notifikasi memakai Navigator existing.
class NotificationOpen {
  const NotificationOpen._();

  static const String votRouteName = '/ai-vot';

  static bool isVotOnTop(NavigatorState? navigator) {
    if (navigator == null) return false;
    Route<dynamic>? top;
    navigator.popUntil((Route<dynamic> route) {
      top ??= route;
      return true;
    });
    return top?.settings.name == votRouteName;
  }

  static void go(BuildContext context, NotificationModel item) {
    final NavigatorState navigator = Navigator.of(context);
    if (isVotOnTop(navigator)) return;

    switch (NotificationTap.targetOf(item)) {
      case NotificationOpenTarget.home:
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const HomePage(),
          ),
        );
        return;
      case NotificationOpenTarget.controlSchedule:
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MedicinePage(
              highlightedControlScheduleId: item.referenceId,
            ),
          ),
        );
        return;
      case NotificationOpenTarget.complaintHistory:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ReportPage(
              highlightedComplaintId: NotificationTap.complaintId(item),
            ),
          ),
        );
        return;
      case NotificationOpenTarget.refillHistory:
        navigator.push(
          MaterialPageRoute<void>(
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
        navigator.push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: votRouteName),
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
}
