import 'package:flutter/services.dart';

/// WHO Anthro daily length/height-for-age LMS values, ages 0-1826 days.
class WhoHeightReference {
  final Map<String, Map<int, ({double median, double spread})>> values;
  WhoHeightReference._(this.values);

  static Future<WhoHeightReference> load() async {
    final text = await rootBundle.loadString('assets/who/lenanthro.txt');
    final result = <String, Map<int, ({double median, double spread})>>{
      'male': {},
      'female': {}
    };
    for (final line in text.split('\n').skip(1)) {
      final row = line.trim().split(RegExp(r'\s+'));
      if (row.length < 6) continue;
      final sex = row[0] == '1'
          ? 'male'
          : row[0] == '2'
              ? 'female'
              : null;
      if (sex == null) continue;
      final age = int.tryParse(row[1]);
      final median = double.tryParse(row[3]);
      final spread = double.tryParse(row[4]);
      if (age != null && median != null && spread != null)
        result[sex]![age] = (median: median, spread: spread);
    }
    if (result['male']!.length != 1827 || result['female']!.length != 1827)
      throw const FormatException('Incomplete WHO reference');
    return WhoHeightReference._(result);
  }

  static int ageDays(DateTime birth, DateTime measured) =>
      DateTime.utc(measured.year, measured.month, measured.day)
          .difference(DateTime.utc(birth.year, birth.month, birth.day))
          .inDays;

  ({int age, double adjustedHeight, double z})? assess(
      {required String sex,
      required DateTime birth,
      required DateTime date,
      required double height,
      required String method}) {
    final age = ageDays(birth, date);
    final ref = values[sex]?[age];
    if (ref == null ||
        height <= 0 ||
        !height.isFinite ||
        (method != 'standing' && method != 'lying')) return null;
    var adjusted = height;
    if (age < 731 && method == 'standing') adjusted += 0.7;
    if (age >= 731 && method == 'lying') adjusted -= 0.7;
    if (adjusted <= 0) return null;
    // WHO length/height-for-age reference has L = 1 for all ages.
    final z = (adjusted / ref.median - 1) / ref.spread;
    return (age: age, adjustedHeight: adjusted, z: z);
  }
}
