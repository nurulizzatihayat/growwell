import 'package:flutter/material.dart';
import 'child_age.dart';

/// One latest measurement per calendar month, newest first.
List<Map<String, Object?>> monthlyMeasurements(List<Map<String, Object?>> records) {
  final sorted = [...records]..sort((a, b) {
    final byDate = (b['date'] as String).compareTo(a['date'] as String);
    return byDate != 0 ? byDate : ((b['id'] as int?) ?? 0).compareTo((a['id'] as int?) ?? 0);
  });
  final months = <String>{};
  return sorted.where((record) => months.add((record['date'] as String).substring(0, 7))).toList();
}

class MonthlyProgress extends StatelessWidget {
  final Map<String, Object?> child;
  final List<Map<String, Object?>> records;
  const MonthlyProgress({super.key, required this.child, required this.records});

  @override
  Widget build(BuildContext context) {
    final months = monthlyMeasurements(records);
    if (months.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Add a measurement to see monthly progress.')));
    String change(num current, num previous, String unit) {
      final delta = current - previous;
      return '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';
    }
    final birth = DateTime.parse(child['birth'] as String);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text('Monthly progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      const Text('Latest measurement for each month', style: TextStyle(color: Colors.black54)),
      for (var i = 0; i < months.length; i++)
        Card(child: ListTile(
          title: Text('${months[i]['date']} · ${ageInMonths(birth, DateTime.parse(months[i]['date'] as String))}'),
          subtitle: Text('${months[i]['height']} cm  •  ${months[i]['weight']} kg${i + 1 < months.length ? '\nChange since ${months[i + 1]['date']}: ${change(months[i]['height'] as num, months[i + 1]['height'] as num, 'cm')}  •  ${change(months[i]['weight'] as num, months[i + 1]['weight'] as num, 'kg')}' : ''}'),
        )),
    ]);
  }
}
