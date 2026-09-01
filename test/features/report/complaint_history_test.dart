import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/report/models/complaint.dart';
import 'package:sitara/features/report/widgets/report_history_section.dart';

Complaint _complaint({
  required int id,
  String? response,
}) {
  return Complaint(
    id: id,
    treatmentId: 1,
    handledBy: response == null ? null : 2,
    category: 'Mual / Muntah',
    description: 'Mual setelah minum obat',
    status: response == null ? 'pending' : 'in_progress',
    response: response,
    isActive: true,
    createdAt: '2026-08-26T10:00:00',
    updatedAt: '2026-08-26T11:00:00',
  );
}

void main() {
  testWidgets('complaint history shows nakes reply from GET /complaints/my',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportHistorySection(
            complaints: <Complaint>[
              _complaint(id: 42, response: 'Silakan istirahat.'),
            ],
            highlightedComplaintId: 42,
          ),
        ),
      ),
    );

    expect(find.text('Balasan Petugas'), findsOneWidget);
    expect(find.text('Silakan istirahat.'), findsOneWidget);
    expect(find.text('Mual / Muntah'), findsOneWidget);
  });

  testWidgets('missing complaint id still shows history without fake item',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportHistorySection(
            complaints: <Complaint>[_complaint(id: 1)],
            highlightedComplaintId: 99,
          ),
        ),
      ),
    );

    expect(find.text('Mual / Muntah'), findsOneWidget);
    expect(find.text('Belum ada keluhan yang dikirim'), findsNothing);
  });
}
