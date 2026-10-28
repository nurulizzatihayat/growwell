import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growwell/growth_page.dart';
import 'package:growwell/growth_repository.dart';

class FakeGrowthRepository extends GrowthRepository {
  List<Map<String, Object?>> list = [
    {'id': 1, 'name': 'First'}
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
    Widget page(int id) => MaterialApp(
        home: Scaffold(
            body: GrowthPage(
                ownerId: 'a', initialChildId: id, repository: repo)));
    await tester.pumpWidget(page(1));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.byTooltip('Add child'), findsNothing);
    repo.pending = Completer<List<Map<String, Object?>>>();
    await tester.pumpWidget(page(4));
    await tester.pump();
    expect(tester.takeException(), isNull);
    repo.pending!.complete([
      {'id': 1, 'name': 'First'},
      {'id': 4, 'name': 'New child'}
    ]);
    await tester.pumpAndSettle();
    expect(find.text('New child'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
