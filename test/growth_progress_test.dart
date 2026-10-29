import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/growth_page.dart';
import 'package:growwell/growth_repository.dart';
import 'package:growwell/height_chart.dart';
import 'package:growwell/who_height_reference.dart';

class RecordsRepository extends GrowthRepository {
  @override
  Future<List<Map<String, Object?>>> children(String owner) async => [
        {'id': 1, 'name': 'Test', 'birth': '2022-01-15', 'sex': 'male'}
      ];
  @override
  Future<List<Map<String, Object?>>> measurements(
          String owner, int childId) async =>
      [
        {
          'id': 2,
          'date': '2026-04-20',
          'height': 100.0,
          'weight': 15.0,
          'method': 'standing'
        },
        {
          'id': 1,
          'date': '2025-03-10',
          'height': 90.0,
          'weight': 13.0,
          'method': 'standing'
        },
      ];
}

void main() {
  test('age uses birth and measurement dates', () {
    expect(
        measurementAge(DateTime(2022, 1, 15), DateTime(2025, 3, 10)), '3y 1m');
    expect(
        measurementAge(DateTime(2022, 1, 15), DateTime(2025, 3, 15)), '3y 2m');
  });
  testWidgets('history selects a record and progress shows both records',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final who = (await tester.runAsync(() => WhoHeightReference.load()))!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GrowthPage(
                ownerId: 'a',
                initialChildId: 1,
                repository: RecordsRepository(),
                heightReference: Future.value(who)))));
    await tester.pumpAndSettle();
    expect(find.textContaining('100.0 cm, 4y 3m'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2025-03-10'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Age: 3y 1m'), findsOneWidget);
    await tester.tap(find.text('2025-03-10'));
    await tester.pumpAndSettle();
    expect(find.textContaining('90.0 cm, 3y 1m'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('View Growth Progress'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('View Growth Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Growth Progress'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Growth progress chart, showing 2 valid measurements'),
        findsOneWidget);
    expect(find.text('2026-04-20'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2025-03-10'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('2025-03-10'), findsOneWidget);
  });
}
