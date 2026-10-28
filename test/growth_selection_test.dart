import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/growth_page.dart';
import 'package:growwell/growth_repository.dart';
import 'package:growwell/who_height_reference.dart';

class FakeGrowthRepository extends GrowthRepository {
  List<Map<String, Object?>> list = [
    {'id': 1, 'name': 'First', 'sex': 'male', 'birth': '2022-01-01'}
  ];
  Completer<List<Map<String, Object?>>>? pending;
  @override
  Future<List<Map<String, Object?>>> children(String owner) =>
      pending?.future ?? Future.value(List.of(list));
  @override
  Future<List<Map<String, Object?>>> measurements(String owner, int id) async =>
      [];
}

void main() {
  testWidgets('changing to a newly added child waits for the updated list',
      (tester) async {
    final repo = FakeGrowthRepository();
    final who = (await tester.runAsync(() => WhoHeightReference.load()))!;
    Widget page(int id) => MaterialApp(
        home: Scaffold(
            body: GrowthPage(
                ownerId: 'a',
                initialChildId: id,
                repository: repo,
                heightReference: Future.value(who))));
    await tester.pumpWidget(page(1));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.byTooltip('Add child'), findsNothing);
    repo.pending = Completer<List<Map<String, Object?>>>();
    await tester.pumpWidget(page(4));
    await tester.pump();
    expect(tester.takeException(), isNull);
    repo.pending!.complete([
      {'id': 1, 'name': 'First', 'sex': 'male', 'birth': '2022-01-01'},
      {'id': 4, 'name': 'New child', 'sex': 'female', 'birth': '2022-01-01'}
    ]);
    await tester.pumpAndSettle();
    expect(find.text('New child'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
