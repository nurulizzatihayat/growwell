import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/growth_reference_chart.dart';

void main() {
  testWidgets('reference switches at 60 and 61 months for both sexes', (tester) async {
    final data = (await tester.runAsync(() => rootBundle.loadString('assets/who/growth_curves.csv')))!;
    Future<void> show(String sex, String date, String indicator) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: GrowthReferenceChart(
        child: {'birth': '2020-01-01', 'sex': sex},
        record: {'date': date, 'height': 110.0, 'weight': 18.0, 'method': 'unknown'},
        indicator: indicator, reference: Future.value(data), today: DateTime.parse(date))))));
      await tester.pumpAndSettle();
    }
    for (final sex in ['male', 'female']) {
      for (final indicator in ['height', 'weight', 'bmi']) {
        await show(sex, '2025-01-01', indicator);
        expect(find.textContaining('WHO 2006'), findsOneWidget);
        await show(sex, '2025-02-01', indicator);
        expect(find.textContaining('WHO 2007'), findsOneWidget);
        expect(find.textContaining('at 61 months'), findsOneWidget);
      }
    }
    await show('male', '2030-01-01', 'weight');
    expect(find.textContaining('WHO 2007'), findsOneWidget);
    await show('male', '2030-02-01', 'weight');
    expect(find.textContaining('unavailable after 120 months'), findsOneWidget);
    await show('male', '2030-02-01', 'bmi');
    expect(find.textContaining('at 121 months'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GrowthReferenceChart(
      child: const {'birth': '2020-01-01', 'sex': 'male'},
      record: const {'date': '2025-01-01', 'height': 110.0, 'weight': 18.0},
      indicator: 'height', reference: Future.value(data), today: DateTime(2025, 2, 1)))));
    await tester.pumpAndSettle();
    expect(find.textContaining('WHO 2007'), findsOneWidget);
    expect(find.textContaining('outside this chart’s age range'), findsOneWidget);
  });

  testWidgets('WHO tables contain expected examples for both sexes', (tester) async {
    final data = (await tester.runAsync(() => rootBundle.loadString('assets/who/growth_curves.csv')))!;
    final lines = data.trim().split('\n').skip(1).map((s) => s.trim().split(',')).toList();
    List<String> row(String metric, String sex, int year, int month) => lines.singleWhere((r) => r[0] == metric && r[1] == sex && r[2] == '$year' && r[3] == '$month');
    expect(double.parse(row('height', 'girls', 2007, 61)[7]), closeTo(109.602, 0.001));
    expect(double.parse(row('weight', 'boys', 2006, 0)[7]), closeTo(3.3, 0.001));
    expect(double.parse(row('bmi', 'boys', 2007, 61)[7]), closeTo(15.264, 0.001));
    expect(lines.length, 1158);
  });
}
