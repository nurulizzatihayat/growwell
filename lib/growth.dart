
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database.dart';

class GrowthPage extends StatefulWidget {
  final String ownerId;
  final String? initialChildId;
  final bool visible;
  final ValueChanged<String>? onChildSelected;
  final GrowthRepository? repository;
  final Future<String>? heightReference;
  final Future<bool> Function(String childId, String date)? scheduleReminder;

  const GrowthPage({
    super.key,
    required this.ownerId,
    this.initialChildId,
    this.visible = true,
    this.onChildSelected,
    this.repository,
    this.heightReference,
    this.scheduleReminder,
  });

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  late final GrowthRepository repo =
      widget.repository ?? GrowthRepository();

  List<Map<String, Object?>> children = [];
  List<Map<String, Object?>> records = [];

  String? selectedId;
  String? selectedMeasurementId;

  int indicator = 0;

  final ScrollController scrollController = ScrollController();

  bool loading = true;
  String? error;
  int loadRequest = 0;
  String? reminderKey;

  @override
  void initState() {
    super.initState();
    selectedId = widget.initialChildId;
    load();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrowthPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialChildId != oldWidget.initialChildId ||
        (widget.visible && !oldWidget.visible)) {
      if (widget.initialChildId != null &&
          widget.initialChildId != selectedId) {
        selectedId = widget.initialChildId;
        selectedMeasurementId = null;
      }

      loading = true;
      load();
    }
  }

  Future<void> load() async {
    final request = ++loadRequest;

    try {
      final list = await repo.children(widget.ownerId);

      final id = list.any((c) => c['id'] == selectedId)
          ? selectedId
          : (list.isEmpty ? null : list.first['id'] as String);

      final entries = id == null
          ? <Map<String, Object?>>[]
          : await repo.measurements(widget.ownerId, id);

      if (!mounted || request != loadRequest) return;

      setState(() {
        if (selectedId != id ||
            !entries.any(
              (entry) => entry['id'] == selectedMeasurementId,
            )) {
          selectedMeasurementId = entries.isEmpty
              ? null
              : entries.first['id'] as String;
        }

        children = list;
        selectedId = id;
        records = entries;
        loading = false;
        error = null;
      });

      if (widget.visible && id != null && entries.isNotEmpty) {
        final date = entries.first['date'] as String;

        final name = list.firstWhere(
          (c) => c['id'] == id,
        )['name'] as String;

        final key = '$id:$date:$name';

        if (key != reminderKey) {
          reminderKey = key;
          _scheduleReminder(id, name, date);
        }
      }
    } catch (e, st) {
      debugPrint('Growth load failed: $e\n$st');

      if (mounted && request == loadRequest) {
        setState(() {
          loading = false;
          error = 'Could not load growth data.';
        });
      }
    }
  }

  Future<void> _scheduleReminder(
    String childId,
    String childName,
    String date,
  ) async {
    if (widget.scheduleReminder == null &&
        !GrowthReminders.supported) {
      return;
    }

    try {
      final allowed = widget.scheduleReminder != null
          ? await widget.scheduleReminder!(childId, date)
          : await GrowthReminders.schedule(
              childId: childId,
              childName: childName,
              latestDate: date,
            );

      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow notifications in your phone settings to receive growth reminders.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Measurement saved. The reminder could not be scheduled.',
            ),
          ),
        );
      }
    }
  }

  Future<void> addMeasurement() async {
    final height = TextEditingController();
    final weight = TextEditingController();

    DateTime date = DateUtils.dateOnly(DateTime.now());

    final child = children.firstWhere(
      (c) => c['id'] == selectedId,
    );

    final birth = DateTime.parse(child['birth'] as String);

    final route = DialogRoute<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add measurement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: birth,
                      lastDate: DateTime.now(),
                      initialDate: date,
                    );

                    if (d != null) {
                      update(() => date = d);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateText(date)),
                ),
                TextField(
                  controller: height,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Height or length (cm)',
                  ),
                ),
                TextField(
                  controller: weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final h = double.tryParse(height.text);
                final w = double.tryParse(weight.text);

                if (h == null ||
                    w == null ||
                    !h.isFinite ||
                    !w.isFinite ||
                    h <= 0 ||
                    w <= 0 ||
                    date.isBefore(birth)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter valid positive measurements and a date after birth.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    final result = await Navigator.of(context).push(route);
    await route.completed;

    if (result == true) {
      try {
        selectedMeasurementId = await repo.addMeasurement(
          widget.ownerId,
          selectedId!,
          dateText(date),
          double.parse(height.text),
          double.parse(weight.text),
          'unknown',
        );

        await load();
      } catch (_) {
        showError();
      }
    }

    height.dispose();
    weight.dispose();
  }

  void showError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Please try again.'),
        ),
      );
    }
  }

  String dateText(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const green = Color(0xFF1DA270);

  static const labels = [
    'Height-for-Age',
    'Weight-for-Age',
    'BMI-for-Age',
  ];

  @override
  Widget build(BuildContext context) {
    final child = selectedId == null || children.isEmpty
        ? null
        : children.where((c) => c['id'] == selectedId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _GrowthHeader(),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(error!),
                                TextButton(
                                  onPressed: load,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(14),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: children.isEmpty
                                        ? const Text(
                                            'Add a child on the Home page to get started.',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          )
                                        : DropdownButtonFormField<String>(
                                            key: ValueKey(selectedId),
                                            initialValue: children.any(
                                              (c) =>
                                                  c['id'] == selectedId,
                                            )
                                                ? selectedId
                                                : null,
                                            decoration:
                                                const InputDecoration(
                                              labelText:
                                                  'Selected child',
                                              border:
                                                  OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            items: children
                                                .map(
                                                  (c) =>
                                                      DropdownMenuItem<
                                                          String>(
                                                    value:
                                                        c['id'] as String,
                                                    child: Text(
                                                      c['name'] as String,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (id) {
                                              setState(() {
                                                selectedId = id;
                                                selectedMeasurementId =
                                                    null;
                                                records = [];
                                              });

                                              if (id != null) {
                                                widget.onChildSelected
                                                    ?.call(id);
                                              }

                                              load();
                                            },
                                          ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    labels.length,
                                    (i) => Padding(
                                      padding:
                                          const EdgeInsets.only(
                                        right: 6,
                                      ),
                                      child: ChoiceChip(
                                        label: Text(labels[i]),
                                        selected: indicator == i,
                                        selectedColor: green,
                                        backgroundColor:
                                            const Color(0xFFEDEFF4),
                                        labelStyle: TextStyle(
                                          color: indicator == i
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        onSelected: (_) => setState(
                                          () => indicator = i,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              GrowthReferenceChart(
                                child: child,
                                reference: widget.heightReference,
                                indicator: [
                                  'height',
                                  'weight',
                                  'bmi',
                                ][indicator],
                                record: records
                                    .where(
                                      (r) =>
                                          r['id'] ==
                                          selectedMeasurementId,
                                    )
                                    .firstOrNull,
                              ),

                              const SizedBox(height: 16),

                              if (child != null)
                                MonthlyProgress(
                                  child: child,
                                  records: records,
                                ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Measurement History',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: child == null
                                        ? null
                                        : addMeasurement,
                                    icon: const Icon(Icons.add),
                                    label: const Text(
                                      'Add measurement',
                                    ),
                                  ),
                                ],
                              ),

                              if (child == null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    'Select or add a child first.',
                                  ),
                                )
                              else if (records.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    'No measurements yet.',
                                  ),
                                )
                              else
                                ...records.map(
                                  (r) => Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    child: ListTile(
                                      selected: r['id'] ==
                                          selectedMeasurementId,
                                      selectedTileColor:
                                          const Color(0xFFE3F5EB),
                                      onTap: () {
                                        setState(() {
                                          selectedMeasurementId =
                                              r['id'] as String;
                                          indicator = 0;
                                        });

                                        scrollController.animateTo(
                                          0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                      title: Text(
                                        r['date'] as String,
                                      ),
                                      subtitle: Text(
                                        'Age: ${ageInMonths(DateTime.parse(child['birth'] as String), DateTime.parse(r['date'] as String))}  •  ${r['height']} cm  •  ${r['weight']} kg',
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///siCILIK app header.
class _GrowthHeader extends StatelessWidget {
  const _GrowthHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.trending_up_rounded,
              color: Color(0xFFF2C230),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres Pertumbuhan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lihat carta pertumbuhan anak anda dan rekod bulanan.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

int? completedAgeMonths(DateTime birth, DateTime date) {
  var months =
      (date.year - birth.year) * 12 + date.month - birth.month;

  if (date.day < birth.day) months--;

  return months < 0 ? null : months;
}

String ageInMonths(DateTime birth, DateTime date) {
  final months = completedAgeMonths(birth, date);

  if (months == null) return 'Age unavailable';

  return '$months ${months == 1 ? 'month' : 'months'}';
}

class GrowthReferenceChart extends StatefulWidget {
  final Map<String, Object?>? child;
  final Map<String, Object?>? record;
  final String indicator;
  final Future<String>? reference;
  final DateTime? today;

  const GrowthReferenceChart({
    super.key,
    this.child,
    this.record,
    required this.indicator,
    this.reference,
    this.today,
  });

  @override
  State<GrowthReferenceChart> createState() =>
      _GrowthReferenceChartState();
}

class _GrowthReferenceChartState
    extends State<GrowthReferenceChart> {
  late final Future<String> data =
      widget.reference ??
      rootBundle.loadString('assets/who/growth_curves.csv');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Unable to load growth reference data.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final child = widget.child;

          if (child == null) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select a child to view the chart.',
                ),
              ),
            );
          }

          final birth = DateTime.parse(child['birth'] as String);
          final record = widget.record;

          final age = completedAgeMonths(
            birth,
            widget.today ?? DateTime.now(),
          );

          final measurementAge = record == null
              ? null
              : completedAgeMonths(
                  birth,
                  DateTime.parse(record['date'] as String),
                );

          final sex = child['sex'] == 'male' ? 'boys' : 'girls';

          final name = {
            'height': 'Height-for-age',
            'weight': 'Weight-for-age',
            'bmi': 'BMI-for-age',
          }[widget.indicator]!;

          if (age == null ||
              age > 228 ||
              (widget.indicator == 'weight' && age > 120)) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.indicator == 'weight' &&
                          age != null &&
                          age > 120
                      ? 'Weight-for-age reference data is unavailable after 120 months.'
                      : 'Growth reference data is unavailable for this age.',
                ),
              ),
            );
          }

          final year = age <= 60 ? 2006 : 2007;

          final canPlot = measurementAge != null &&
              (year == 2006
                  ? measurementAge <= 60
                  : measurementAge >= 61) &&
              measurementAge <=
                  (widget.indicator == 'weight' ? 120 : 228);

          final rows = snapshot.data!
              .trim()
              .split('\n')
              .skip(1)
              .map((line) => line.trim().split(','))
              .where(
                (row) =>
                    row[0] == widget.indicator &&
                    row[1] == sex &&
                    row[2] == '$year',
              )
              .map(
                (row) => row.skip(3).map(double.parse).toList(),
              )
              .toList();

          if (rows.isEmpty) {
            return const Text(
              'Growth reference data is unavailable.',
            );
          }

          final height =
              (record?['height'] as num?)?.toDouble();

          final weight =
              (record?['weight'] as num?)?.toDouble();

          final double? value = switch (widget.indicator) {
            'height' => height,
            'weight' => weight,
            'bmi' =>
              height != null &&
                      height > 0 &&
                      weight != null
                  ? weight / math.pow(height / 100, 2)
                  : null,
            _ => null,
          };

          final unit = widget.indicator == 'height'
              ? 'cm'
              : widget.indicator == 'weight'
                  ? 'kg'
                  : 'kg/m²';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name · WHO $year ($sex)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _GrowthPainter(
                        rows,
                        value == null || !canPlot
                            ? null
                            : measurementAge,
                        value,
                        unit,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value == null
                        ? 'Add a measurement to plot it.'
                        : !canPlot
                            ? 'The selected measurement was recorded outside this chart’s age range.'
                            : 'Measurement: ${value.toStringAsFixed(1)} $unit at $measurementAge months.',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lines show WHO z-score references. This chart is not a diagnosis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _GrowthPainter extends CustomPainter {
  final List<List<double>> rows;
  final int? age;
  final double? value;
  final String unit;

  _GrowthPainter(
    this.rows,
    this.age,
    this.value,
    this.unit,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.length < 2) return;

    final plot = Rect.fromLTRB(
      40,
      12,
      size.width - 30,
      size.height - 36,
    );

    if (plot.width <= 0 || plot.height <= 0) return;

    final start = rows.first[0];
    final end = rows.last[0];

    final values = rows.expand((r) => r.skip(1)).toList();

    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);

    if (value != null && value!.isFinite) {
      minY = math.min(minY, value!);
      maxY = math.max(maxY, value!);
    }

    final pad = (maxY - minY) * 0.08;

    minY = math.max(0, minY - pad);
    maxY += pad;

    double x(double month) =>
        plot.left +
        (month - start) / (end - start) * plot.width;

    double y(double n) =>
        plot.bottom -
        (n - minY) / (maxY - minY) * plot.height;

    void label(String text, Offset offset) {
      (TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout())
          .paint(canvas, offset);
    }

    final grid = Paint()
      ..color = const Color(0xFFE4E6EA);

    for (var i = 0; i <= 4; i++) {
      final n = minY + (maxY - minY) * i / 4;

      canvas.drawLine(
        Offset(plot.left, y(n)),
        Offset(plot.right, y(n)),
        grid,
      );

      label(
        n.toStringAsFixed(n < 30 ? 1 : 0),
        Offset(0, y(n) - 6),
      );

      final month = start + (end - start) * i / 4;

      canvas.drawLine(
        Offset(x(month), plot.top),
        Offset(x(month), plot.bottom),
        grid,
      );

      label(
        '${month.round()}',
        Offset(x(month) - 8, plot.bottom + 3),
      );
    }

    canvas.save();
    canvas.clipRect(plot);

    for (var i = 1; i <= 7; i++) {
      final path = Path();

      for (var n = 0; n < rows.length; n++) {
        final row = rows[n];

        if (n == 0) {
          path.moveTo(x(row[0]), y(row[i]));
        } else {
          path.lineTo(x(row[0]), y(row[i]));
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = i == 4
              ? const Color(0xFF1DA270)
              : Colors.blueGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 4 ? 2 : 1,
      );
    }

    if (age != null && value != null && value!.isFinite) {
      canvas.drawCircle(
        Offset(x(age!.toDouble()), y(value!)),
        5,
        Paint()..color = Colors.red,
      );
    }

    canvas.restore();

    for (var i = 1; i <= 7; i++) {
      final score = i - 4;

      label(
        score > 0 ? '+$score' : '$score',
        Offset(plot.right + 3, y(rows.last[i]) - 6),
      );
    }

    label(unit, const Offset(0, 0));

    label(
      'Age (months)',
      Offset(plot.center.dx - 25, size.height - 12),
    );
  }

  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) => true;
}

/// One latest measurement per calendar month, newest first.
List<Map<String, Object?>> monthlyMeasurements(
  List<Map<String, Object?>> records,
) {
  final sorted = [...records]
    ..sort((a, b) {
      final byDate =
          (b['date'] as String).compareTo(a['date'] as String);

      return byDate != 0
          ? byDate
          : ((b['createdAt'] as num?) ?? 0).compareTo(
              (a['createdAt'] as num?) ?? 0,
            );
    });

  final months = <String>{};

  return sorted
      .where(
        (record) =>
            months.add(
              (record['date'] as String).substring(0, 7),
            ),
      )
      .toList();
}

class MonthlyProgress extends StatelessWidget {
  final Map<String, Object?> child;
  final List<Map<String, Object?>> records;

  const MonthlyProgress({
    super.key,
    required this.child,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final months = monthlyMeasurements(records);

    if (months.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Add a measurement to see monthly progress.',
          ),
        ),
      );
    }

    String change(num current, num previous, String unit) {
      final delta = current - previous;

      return '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';
    }

    final birth = DateTime.parse(child['birth'] as String);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            'Monthly progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(
          'Latest measurement for each month',
          style: TextStyle(color: Colors.black54),
        ),
        for (var i = 0; i < months.length; i++)
          Card(
            child: ListTile(
              title: Text(
                '${months[i]['date']} · ${ageInMonths(birth, DateTime.parse(months[i]['date'] as String))}',
              ),
              subtitle: Text(
                '${months[i]['height']} cm  •  ${months[i]['weight']} kg${i + 1 < months.length ? '\nChange since ${months[i + 1]['date']}: ${change(months[i]['height'] as num, months[i + 1]['height'] as num, 'cm')}  •  ${change(months[i]['weight'] as num, months[i + 1]['weight'] as num, 'kg')}' : ''}',
              ),
            ),
          ),
      ],
    );
  }
}

class GrowthReminders {
  static const _channel =
      MethodChannel('growwell/growth_reminders');

  static final _notifications =
      FlutterLocalNotificationsPlugin();

  static bool get supported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static Future<void> cancelLegacy() async {
    if (!supported) {
      return;
    }

    try {
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            '@mipmap/ic_launcher',
          ),
        ),
      );

      await _notifications.cancel(id: 731002);
    } catch (_) {
      // The new reminder is scheduled separately; retry on the next launch.
    }
  }

  static Future<bool> schedule({
    required String childId,
    required String childName,
    required String latestDate,
  }) async {
    if (!supported) {
      return false;
    }

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
      ),
    );

    await _notifications.cancel(id: 731002);

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final allowed =
        await android?.requestNotificationsPermission();

    await _channel.invokeMethod<void>('schedule', {
      'childId': childId,
      'name': childName,
      'date': latestDate,
    });

    return allowed != false;
  }
}
