import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/home_preview.dart';
import 'package:growwell/growth_repository.dart';

class FakeRepository extends GrowthRepository {
  final List<Map<String, Object?>> data;
  FakeRepository(this.data);
  @override
  Future<List<Map<String, Object?>>> children(String owner) async => data;
  @override
  Future<String?> profileName(String owner) async => 'Nurul';
  @override
  Future<int> addChild(
      String owner, String name, String birth, String sex) async {
    data.add({'id': 7, 'name': name, 'birth': birth, 'sex': sex});
    return 7;
  }

  @override
  Future<void> updateChild(String owner, int id, String name, String birth, String sex) async {
    final index = data.indexWhere((child) => child['id'] == id);
    data[index] = {'id': id, 'name': name, 'birth': birth, 'sex': sex};
  }

  @override
  Future<List<Map<String, Object?>>> measurements(
          String owner, int childId) async =>
      childId == 1
          ? [
              {'date': '2026-10-01', 'height': 92.0, 'weight': 13.5}
            ]
          : [];
}

void main() {
  testWidgets('adds a child to the list', (tester) async {
    final repo = FakeRepository([]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HomePage(
                ownerId: 'a',
                visible: true,
                repository: repo,
                onNavigate: (_) {},
                onChildSelected: (_) {}))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your first child'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alya');
    await tester.tap(find.text('Sex for growth reference'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Girl').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select date of birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Alya'), findsOneWidget);
    expect(repo.data.single['sex'], 'female');
  });
  testWidgets('new account sees add child prompt and no sample child',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HomePage(
                ownerId: 'a',
                visible: true,
                repository: FakeRepository([]),
                onNavigate: (_) {},
                onChildSelected: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to GrowWell'), findsOneWidget);
    expect(find.text('Welcome, Nurul!'), findsOneWidget);
    expect(find.text('Add child'), findsNothing);
    expect(find.text('Add your first child'), findsOneWidget);
    expect(find.text('Adam'), findsNothing);
  });
  testWidgets('selects saved child and displays their measurements',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? selected;
    final repo = FakeRepository([
      {'id': 1, 'name': 'Alya', 'birth': '2022-01-01', 'sex': 'female'}
    ]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HomePage(
                ownerId: 'a',
                visible: true,
                repository: repo,
                onNavigate: (_) {},
                onChildSelected: (id) => selected = id))));
    await tester.pumpAndSettle();
    expect(find.text('Add child'), findsOneWidget);
    await tester.tap(find.text('Alya'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('92.0 cm'), findsOneWidget);
    expect(find.text('13.5 kg'), findsOneWidget);
    expect(find.text('Girl'), findsOneWidget);
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alya Edited');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Alya Edited'), findsOneWidget);
    expect(repo.data.single['name'], 'Alya Edited');
    expect(find.text('All children'), findsNothing);
    await tester.tap(find.byTooltip('Back to children'));
    await tester.pumpAndSettle();
    expect(find.text('Your children'), findsOneWidget);
  });
}
