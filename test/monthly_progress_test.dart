import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:growwell/monthly_progress.dart';

void main() {
  test('uses the latest record from each month, newest month first', () {
    final result = monthlyMeasurements([
      {'id': 1, 'date': '2026-02-01'},
      {'id': 2, 'date': '2026-01-31'},
      {'id': 3, 'date': '2026-02-20'},
      {'id': 4, 'date': '2026-02-20'},
      {'id': 5, 'date': '2025-12-31'},
    ]);
    expect(result.map((r) => r['id']), [4, 2, 5]);
  });
  testWidgets('compares the latest entry with the previous recorded month', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MonthlyProgress(
      child: {'birth': '2023-01-01'},
      records: [
        {'id': 2, 'date': '2026-03-01', 'height': 95.0, 'weight': 15.0},
        {'id': 1, 'date': '2026-01-01', 'height': 93.5, 'weight': 14.5},
      ],
    ))));
    expect(find.textContaining('Change since 2026-01-01: +1.5 cm  •  +0.5 kg'), findsOneWidget);
  });
}
