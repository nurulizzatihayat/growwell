import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'child_age.dart';

class GrowthReferenceChart extends StatefulWidget {
  final Map<String, Object?>? child;
  final Map<String, Object?>? record;
  final String indicator;
  final Future<String>? reference;
  final DateTime? today;
  const GrowthReferenceChart({super.key, this.child, this.record, required this.indicator, this.reference, this.today});

  @override
  State<GrowthReferenceChart> createState() => _GrowthReferenceChartState();
}

class _GrowthReferenceChartState extends State<GrowthReferenceChart> {
  late final Future<String> data = widget.reference ?? rootBundle.loadString('assets/who/growth_curves.csv');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('Unable to load growth reference data.');
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final child = widget.child;
      if (child == null) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Select a child to view the chart.')));
      final birth = DateTime.parse(child['birth'] as String);
      final record = widget.record;
      final age = completedAgeMonths(birth, widget.today ?? DateTime.now());
      final measurementAge = record == null ? null : completedAgeMonths(birth, DateTime.parse(record['date'] as String));
      final sex = child['sex'] == 'male' ? 'boys' : 'girls';
      final name = {'height': 'Height-for-age', 'weight': 'Weight-for-age', 'bmi': 'BMI-for-age'}[widget.indicator]!;
      if (age == null || age > 228 || (widget.indicator == 'weight' && age > 120)) {
        return Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(
          widget.indicator == 'weight' && age != null && age > 120
            ? 'Weight-for-age reference data is unavailable after 120 months.'
            : 'Growth reference data is unavailable for this age.')));
      }
      final year = age <= 60 ? 2006 : 2007;
      final canPlot = measurementAge != null && (year == 2006 ? measurementAge <= 60 : measurementAge >= 61) &&
          measurementAge <= (widget.indicator == 'weight' ? 120 : 228);
      final rows = snapshot.data!.trim().split('\n').skip(1)
        .map((line) => line.trim().split(','))
        .where((row) => row[0] == widget.indicator && row[1] == sex && row[2] == '$year')
        .map((row) => row.skip(3).map(double.parse).toList()).toList();
      if (rows.isEmpty) return const Text('Growth reference data is unavailable.');
      final height = (record?['height'] as num?)?.toDouble();
      final weight = (record?['weight'] as num?)?.toDouble();
      final double? value = switch (widget.indicator) {
        'height' => height,
        'weight' => weight,
        'bmi' => height != null && height > 0 && weight != null ? weight / math.pow(height / 100, 2) : null,
        _ => null,
      };
      final unit = widget.indicator == 'height' ? 'cm' : widget.indicator == 'weight' ? 'kg' : 'kg/m²';
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$name · WHO $year ($sex)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(height: 300, width: double.infinity,
            child: CustomPaint(painter: _GrowthPainter(rows, value == null || !canPlot ? null : measurementAge, value, unit))),
          const SizedBox(height: 10),
          Text(value == null ? 'Add a measurement to plot it.' : !canPlot
              ? 'The selected measurement was recorded outside this chart’s age range.'
              : 'Measurement: ${value.toStringAsFixed(1)} $unit at $measurementAge months.'),
          const SizedBox(height: 6),
          const Text('Lines show WHO z-score references. This chart is not a diagnosis.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ])));
    },
  );
}

class _GrowthPainter extends CustomPainter {
  final List<List<double>> rows;
  final int? age;
  final double? value;
  final String unit;
  _GrowthPainter(this.rows, this.age, this.value, this.unit);
  @override
  void paint(Canvas canvas, Size size) {
    if (rows.length < 2) return;
    final plot = Rect.fromLTRB(40, 12, size.width - 30, size.height - 36);
    if (plot.width <= 0 || plot.height <= 0) return;
    final start = rows.first[0], end = rows.last[0];
    final values = rows.expand((r) => r.skip(1)).toList();
    var minY = values.reduce(math.min), maxY = values.reduce(math.max);
    if (value != null && value!.isFinite) { minY = math.min(minY, value!); maxY = math.max(maxY, value!); }
    final pad = (maxY - minY) * 0.08;
    minY = math.max(0, minY - pad); maxY += pad;
    double x(double month) => plot.left + (month - start) / (end - start) * plot.width;
    double y(double n) => plot.bottom - (n - minY) / (maxY - minY) * plot.height;
    void label(String text, Offset offset) => (TextPainter(text: TextSpan(text: text, style: const TextStyle(color: Colors.black54, fontSize: 10)), textDirection: TextDirection.ltr)..layout()).paint(canvas, offset);
    final grid = Paint()..color = const Color(0xFFE4E6EA);
    for (var i = 0; i <= 4; i++) {
      final n = minY + (maxY - minY) * i / 4;
      canvas.drawLine(Offset(plot.left, y(n)), Offset(plot.right, y(n)), grid);
      label(n.toStringAsFixed(n < 30 ? 1 : 0), Offset(0, y(n) - 6));
      final month = start + (end - start) * i / 4;
      canvas.drawLine(Offset(x(month), plot.top), Offset(x(month), plot.bottom), grid);
      label('${month.round()}', Offset(x(month) - 8, plot.bottom + 3));
    }
    canvas.save(); canvas.clipRect(plot);
    for (var i = 1; i <= 7; i++) {
      final path = Path();
      for (var n = 0; n < rows.length; n++) {
        final row = rows[n];
        if (n == 0) { path.moveTo(x(row[0]), y(row[i])); } else { path.lineTo(x(row[0]), y(row[i])); }
      }
      canvas.drawPath(path, Paint()..color = i == 4 ? const Color(0xFF1DA270) : Colors.blueGrey..style = PaintingStyle.stroke..strokeWidth = i == 4 ? 2 : 1);
    }
    if (age != null && value != null && value!.isFinite) canvas.drawCircle(Offset(x(age!.toDouble()), y(value!)), 5, Paint()..color = Colors.red);
    canvas.restore();
    for (var i = 1; i <= 7; i++) {
      final score = i - 4;
      label(score > 0 ? '+$score' : '$score', Offset(plot.right + 3, y(rows.last[i]) - 6));
    }
    label(unit, const Offset(0, 0));
    label('Age (months)', Offset(plot.center.dx - 25, size.height - 12));
  }
  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) => true;
}
