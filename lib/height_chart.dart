import 'package:flutter/material.dart';
import 'who_height_reference.dart';

String measurementAge(DateTime birth, DateTime date) {
  var months = (date.year - birth.year) * 12 + date.month - birth.month;
  if (date.day < birth.day) months--;
  if (months < 0) return 'Not available';
  return '${months ~/ 12}y ${months % 12}m';
}

typedef HeightPoint = ({int age, double height});

class HeightChart extends StatefulWidget {
  final Map<String, Object?>? child;
  final List<Map<String, Object?>> records;
  final Map<String, Object?>? selectedRecord;
  final bool progress;
  final Future<WhoHeightReference>? reference;
  const HeightChart(
      {super.key,
      required this.child,
      required this.records,
      this.selectedRecord,
      this.progress = false,
      this.reference});
  @override
  State<HeightChart> createState() => _HeightChartState();
}

class _HeightChartState extends State<HeightChart> {
  late final Future<WhoHeightReference> reference =
      widget.reference ?? WhoHeightReference.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<WhoHeightReference>(
      future: reference,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Card(
              child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('WHO reference data could not be loaded.')));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final child = widget.child;
        if (child == null)
          return const Card(
              child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Select a child to see their growth chart.')));
        final who = snapshot.data!;
        final sex = child['sex'] as String;
        final birth = DateTime.parse(child['birth'] as String);
        final record = widget.selectedRecord ??
            (widget.records.isEmpty ? null : widget.records.first);
        ({int age, double adjustedHeight, double z})? assess(
                Map<String, Object?> r) =>
            who.assess(
                sex: sex,
                birth: birth,
                date: DateTime.parse(r['date'] as String),
                height: (r['height'] as num).toDouble(),
                method: r['method'] as String);
        final result = record == null ? null : assess(record);
        final flagged = result != null && (result.z < -6 || result.z > 6);
        final status = result == null
            ? null
            : flagged
                ? 'Measurement needs checking'
                : result.z < -3
                    ? 'Below -3: severe stunting range'
                    : result.z < -2
                        ? 'Below -2: stunting range'
                        : result.z > 3
                            ? 'Above +3: seek assessment'
                            : 'Not in the stunting range';
        final points = <HeightPoint>[];
        for (final r in widget.records.reversed) {
          final entry = assess(r);
          if (entry != null && entry.z >= -6 && entry.z <= 6)
            points.add((age: entry.age, height: entry.adjustedHeight));
        }
        final point = result == null || flagged
            ? null
            : (age: result.age, height: result.adjustedHeight);
        final bool younger =
            !widget.progress && result != null && result.age < 731;
        final start = widget.progress || result == null || younger ? 0 : 731;
        final end = younger ? 730 : 1826;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                  color: Colors.white,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${younger ? 'Length' : 'Length/height'}-for-age (${sex == 'male' ? 'boys' : 'girls'}, ${younger ? '0–2' : start == 731 ? '2–5' : '0–5'} years)',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            SizedBox(
                                height: 300,
                                width: double.infinity,
                                child: Semantics(
                                    label: widget.progress
                                        ? 'Growth progress chart, showing ${points.length} valid measurements'
                                        : 'WHO height for age chart',
                                    child: CustomPaint(
                                        painter: _ChartPainter(
                                            who.values[sex]!,
                                            start,
                                            end,
                                            widget.progress
                                                ? points
                                                : (point == null
                                                    ? []
                                                    : [point]),
                                            widget.progress)))),
                            const SizedBox(height: 8),
                            Text(
                                widget.progress
                                    ? '🟢 Child’s measurements    — WHO reference'
                                    : point == null
                                        ? 'Select a measurement to plot it.'
                                        : '👶 Selected measurement: ${record!['height']} cm, ${measurementAge(birth, DateTime.parse(record['date'] as String))}',
                                style: const TextStyle(fontSize: 12)),
                            if (!widget.progress &&
                                result != null &&
                                record != null &&
                                ((record['height'] as num).toDouble() -
                                            result.adjustedHeight)
                                        .abs() >
                                    0.01)
                              const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                      'The plotted value is adjusted by 0.7 cm for the measurement position, following WHO guidance.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54))),
                            if (!widget.progress) ...[
                              const SizedBox(height: 5),
                              const Text('🟡 Below -2 SD    🔴 Below -3 SD',
                                  style: TextStyle(fontSize: 12)),
                            ],
                            const SizedBox(height: 5),
                            const Text('WHO Child Growth Standards, 2006',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ]))),
              if (widget.progress) ...[
                if (points.length != widget.records.length)
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Some measurements cannot be plotted because they are outside the reference age range or need checking.',
                          style: TextStyle(fontSize: 12))),
              ] else ...[
                Card(
                    color: const Color(0xFFFFF1F2),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Height-for-age Z-score (HAZ)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                  result == null
                                      ? (record == null
                                          ? 'Add a measurement to see a result.'
                                          : 'Reference unavailable for this measurement (supported age: 0–1826 days).')
                                      : flagged
                                          ? 'Check the measurement and date with a healthcare professional.'
                                          : 'Z-score: ${result.z.toStringAsFixed(2)}  •  $status',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              if (result != null && !flagged)
                                const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                        'A screening result is not a diagnosis. Discuss concerns with a healthcare professional.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54))),
                            ]))),
                const Padding(
                    padding: EdgeInsets.fromLTRB(8, 10, 8, 4),
                    child: Text('Interpretation',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const _InterpretationRow(
                    color: Color(0xFFCFEFDD),
                    range: 'HAZ ≥ -2',
                    meaning: 'Not in the stunting range'),
                const _InterpretationRow(
                    color: Color(0xFFFFF3A6),
                    range: '-3 ≤ HAZ < -2',
                    meaning: 'Stunting range'),
                const _InterpretationRow(
                    color: Color(0xFFFFD0D0),
                    range: 'HAZ < -3',
                    meaning: 'Severe stunting range'),
              ],
            ]);
      });
}

class _InterpretationRow extends StatelessWidget {
  final Color color;
  final String range;
  final String meaning;
  const _InterpretationRow(
      {required this.color, required this.range, required this.meaning});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration:
          BoxDecoration(border: Border.all(color: const Color(0xFFE3E5EA))),
      child: Row(children: [
        Container(
            width: 115,
            color: color,
            padding: const EdgeInsets.all(8),
            child: Text(range,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold))),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(meaning, style: const TextStyle(fontSize: 12))))
      ]));
}

class _ChartPainter extends CustomPainter {
  final Map<int, ({double median, double spread})> data;
  final int start, end;
  final List<HeightPoint> points;
  final bool progress;
  _ChartPainter(this.data, this.start, this.end, this.points, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    const left = 37.0, bottom = 34.0, right = 30.0, top = 10.0;
    final rect =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (rect.width <= 0 || rect.height <= 0) return;
    final visible =
        points.where((p) => p.age >= start && p.age <= end).toList();
    double minY = start == 731 ? 70 : 40;
    double maxY = start == 731 ? 130 : 135;
    for (final p in visible) {
      if (p.height < minY) minY = (p.height - 5).clamp(0.0, minY);
      if (p.height > maxY) maxY = p.height + 5;
    }
    double x(double age) =>
        rect.left + rect.width * (age - start) / (end - start);
    double y(double height) =>
        rect.bottom - rect.height * (height - minY) / (maxY - minY);
    void label(String text, Offset pos,
        {Color color = Colors.black54, double fontSize = 9}) {
      final p = TextPainter(
          text: TextSpan(
              text: text, style: TextStyle(fontSize: fontSize, color: color)),
          textDirection: TextDirection.ltr)
        ..layout();
      p.paint(canvas, pos);
    }

    final grid = Paint()
      ..color = const Color(0xFFE4E6EA)
      ..strokeWidth = 1;
    final steps = start == 731
        ? 3
        : end == 730
            ? 2
            : 5;
    for (var i = 0; i <= steps; i++) {
      final xx = rect.left + rect.width * i / steps;
      canvas.drawLine(Offset(xx, rect.top), Offset(xx, rect.bottom), grid);
      label('${start == 731 ? i + 2 : i}y', Offset(xx - 5, rect.bottom + 5));
    }
    for (var h = 0; h <= maxY; h += 10) {
      if (h < minY) continue;
      final yy = y(h.toDouble());
      canvas.drawLine(Offset(rect.left, yy), Offset(rect.right, yy), grid);
      label('$h', Offset(4, yy - 5));
    }
    double curve(int age, int z) {
      final ref = data[age]!;
      return ref.median * (1 + z * ref.spread);
    }

    canvas.save();
    canvas.clipRect(rect);
    if (!progress) {
      Path area(int zTop, int? zBottom) {
        final path = Path()..moveTo(x(start.toDouble()), y(curve(start, zTop)));
        for (var age = start + 7; age < end; age += 7) {
          path.lineTo(x(age.toDouble()), y(curve(age, zTop)));
        }
        path.lineTo(x(end.toDouble()), y(curve(end, zTop)));
        if (zBottom == null) {
          path.lineTo(rect.right, rect.bottom);
          path.lineTo(rect.left, rect.bottom);
        } else {
          path.lineTo(x(end.toDouble()), y(curve(end, zBottom)));
          for (var age = end - 7; age > start; age -= 7) {
            path.lineTo(x(age.toDouble()), y(curve(age, zBottom)));
          }
          path.lineTo(x(start.toDouble()), y(curve(start, zBottom)));
        }
        return path..close();
      }

      canvas.drawPath(area(-3, null), Paint()..color = const Color(0xFFFFB2B4));
      canvas.drawPath(area(-2, -3), Paint()..color = const Color(0xFFFFE77C));
    }
    for (final z in [-3, -2, 0, 2, 3]) {
      final paint = Paint()
        ..color = const Color(0xFF6C7780)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final path = Path()..moveTo(x(start.toDouble()), y(curve(start, z)));
      for (var age = start + 7; age < end; age += 7) {
        path.lineTo(x(age.toDouble()), y(curve(age, z)));
      }
      path.lineTo(x(end.toDouble()), y(curve(end, z)));
      canvas.drawPath(path, paint);
    }
    if (progress && visible.isNotEmpty) {
      final path = Path()
        ..moveTo(x(visible.first.age.toDouble()), y(visible.first.height));
      for (final p in visible.skip(1)) {
        path.lineTo(x(p.age.toDouble()), y(p.height));
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1DA270)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      for (final p in visible) {
        canvas.drawCircle(Offset(x(p.age.toDouble()), y(p.height)), 4,
            Paint()..color = const Color(0xFF1DA270));
      }
    }
    canvas.restore();
    if (!progress && visible.isNotEmpty) {
      final p = visible.first;
      final caption = TextPainter(
          text: TextSpan(
              text: '${p.height.toStringAsFixed(1)} cm',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB21C2A),
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout();
      final bubbleX = (x(p.age.toDouble()) - caption.width / 2 - 6)
          .clamp(rect.left, rect.right - caption.width - 12);
      final bubbleY = (y(p.height) - 39).clamp(rect.top, rect.bottom - 28);
      final bubble = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              bubbleX, bubbleY, caption.width + 12, caption.height + 8),
          const Radius.circular(6));
      canvas.drawRRect(bubble, Paint()..color = const Color(0xFFFFECEC));
      caption.paint(canvas, Offset(bubbleX + 6, bubbleY + 4));
      final emoji = TextPainter(
          text: const TextSpan(text: '👶', style: TextStyle(fontSize: 23)),
          textDirection: TextDirection.ltr)
        ..layout();
      final dx = (x(p.age.toDouble()) - emoji.width / 2)
          .clamp(rect.left, rect.right - emoji.width);
      final dy = (y(p.height) - emoji.height / 2)
          .clamp(rect.top, rect.bottom - emoji.height);
      emoji.paint(canvas, Offset(dx, dy));
    }
    for (final z in [-3, -2, 0, 2, 3]) {
      final yy = y(curve(end, z));
      if (yy >= rect.top && yy <= rect.bottom)
        label(z > 0 ? '+$z' : '$z', Offset(rect.right + 3, yy - 5));
    }
    label('cm', const Offset(2, 0));
    label('Age (years)', Offset(rect.center.dx - 20, size.height - 11));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
