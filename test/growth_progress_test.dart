import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/growth_page.dart';
import 'package:growwell/growth_repository.dart';
import 'package:growwell/child_age.dart';

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

class SavingRepository extends RecordsRepository {
  final saved = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> measurements(String owner, int childId) async =>
      [...saved, ...await super.measurements(owner, childId)];

  @override
  Future<int> addMeasurement(String owner, int childId, String date,
      double height, double weight, String method) async {
    saved.add({'id': 3, 'date': date, 'height': height, 'weight': weight, 'method': method});
    return 3;
  }
}

class OlderChildRepository extends SavingRepository {
  @override
  Future<List<Map<String, Object?>>> children(String owner) async => [
        {'id': 1, 'name': 'Older child', 'birth': '2015-01-15', 'sex': 'male'}
      ];
}

void main() {
  test('age uses birth and measurement dates', () {
    expect(
        ageInMonths(DateTime(2022, 1, 15), DateTime(2025, 3, 10)), '37 months');
    expect(
        ageInMonths(DateTime(2022, 1, 15), DateTime(2025, 3, 15)), '38 months');
    expect(ageInMonths(DateTime(2022, 1, 15), DateTime(2024, 1, 15)), '24 months');
    expect(ageInMonths(DateTime(2022, 1, 15), DateTime(2022, 2, 15)), '1 month');
    expect(ageInMonths(DateTime(2022, 1, 15), DateTime(2022, 1, 14)), 'Age unavailable');
  });
  testWidgets('measurement appears in history after saving',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SavingRepository();
    final scheduled = <String>[];
    final who = (await tester.runAsync(() => rootBundle.loadString('assets/who/growth_curves.csv')))!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GrowthPage(ownerId: 'a', initialChildId: 1,
            repository: repository, heightReference: Future.value(who),
            scheduleReminder: (id, date) async { scheduled.add('$id:$date'); return true; }))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add measurement'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add measurement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Height or length (cm)'), '101.2');
    await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '16.4');
    expect(find.text('How was height measured?'), findsNothing);
    expect(find.text('Enter height measured while standing.'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.saved.single['height'], 101.2);
    expect(repository.saved.single['weight'], 16.4);
    expect(repository.saved.single['method'], 'unknown');
    expect(scheduled.last, '1:${repository.saved.single['date']}');
    expect(find.textContaining('101.2 cm  •  16.4 kg'), findsWidgets);
  });
  testWidgets('older child enters height without a position choice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = OlderChildRepository();
    final who = (await tester.runAsync(() => rootBundle.loadString('assets/who/growth_curves.csv')))!;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GrowthPage(
        ownerId: 'a', initialChildId: 1, repository: repository, heightReference: Future.value(who),
        scheduleReminder: (_, __) async => true))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add measurement'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add measurement'));
    await tester.pumpAndSettle();
    expect(find.text('How was height measured?'), findsNothing);
    expect(find.text('Enter height measured while standing.'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Height or length (cm)'), '140');
    await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '35');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.saved.single['method'], 'unknown');
  });
  testWidgets('history shows measurements and WHO 2007 age range', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final who = (await tester.runAsync(() => rootBundle.loadString('assets/who/growth_curves.csv')))!;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GrowthPage(
        ownerId: 'a', initialChildId: 1, repository: RecordsRepository(), heightReference: Future.value(who),
        scheduleReminder: (_, __) async => true))));
    await tester.pumpAndSettle();
    expect(find.textContaining('WHO 2006'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2025-03-10'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Age: 37 months'), findsOneWidget);
  });
}
