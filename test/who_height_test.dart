import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/who_height_reference.dart';
import 'package:growwell/height_chart.dart';

void main() {
  testWidgets('WHO daily reference, adjustment and age boundaries',
      (tester) async {
    final who = (await tester.runAsync(() => WhoHeightReference.load()))!;
    final born = DateTime.utc(2020, 1, 1);
    // WHO anthro's published example: boy, 44 days, length 50 cm.
    final whoExample = who.assess(
        sex: 'male', birth: born, date: born.add(const Duration(days: 44)),
        height: 50, method: 'lying')!;
    expect(whoExample.z, closeTo(((50 / 56.4833) - 1) / 0.03492, 0.000001));
    final date = born.add(const Duration(days: 731));
    final result = who.assess(
        sex: 'male',
        birth: born,
        date: date,
        height: 87.1303,
        method: 'standing')!;
    expect(result.z, closeTo(0, 0.000001));
    final lying = who.assess(
        sex: 'male',
        birth: born,
        date: date,
        height: 87.8303,
        method: 'lying')!;
    expect(lying.z, closeTo(0, 0.000001));
    final before = who.assess(
        sex: 'male',
        birth: born,
        date: born.add(const Duration(days: 730)),
        height: 87.1018,
        method: 'standing')!;
    expect(before.z, closeTo(0, 0.000001));
    expect(
        who.assess(
            sex: 'male',
            birth: born,
            date: born.add(const Duration(days: 1827)),
            height: 100,
            method: 'standing'),
        isNull);
    expect(
        who.assess(
            sex: 'female',
            birth: born,
            date: born.subtract(const Duration(days: 1)),
            height: 50,
            method: 'lying'),
        isNull);
  });

  testWidgets(
      'height chart shows WHO result and flags questionable measurements',
      (tester) async {
    final who = (await tester.runAsync(() => WhoHeightReference.load()))!;
    final child = {
      'id': 1,
      'name': 'Test',
      'birth': '2020-01-01',
      'sex': 'male'
    };
    Widget page(double height) => MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: HeightChart(
                        child: child,
                        reference: Future.value(who),
                        records: [
              {'date': '2022-01-01', 'height': height, 'method': 'standing'}
            ]))));
    await tester.pumpWidget(page(87.1303));
    await tester.pumpAndSettle();
    expect(find.textContaining('•  Not in the stunting range'), findsOneWidget);
    await tester.pumpWidget(page(80));
    await tester.pumpAndSettle();
    expect(find.textContaining('Below -2: stunting range'), findsOneWidget);
    await tester.pumpWidget(page(77));
    await tester.pumpAndSettle();
    expect(find.textContaining('Below -3: severe stunting range'), findsOneWidget);
    await tester.pumpWidget(page(10));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Check the measurement and date with a healthcare professional.'),
        findsOneWidget);
  });
}
