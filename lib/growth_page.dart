import 'package:flutter/material.dart';
import 'growth_repository.dart';

class GrowthPage extends StatefulWidget {
  final String ownerId;
  final int? initialChildId;
  final bool visible;
  final ValueChanged<int>? onChildSelected;
  final GrowthRepository? repository;
  const GrowthPage(
      {super.key,
      required this.ownerId,
      this.initialChildId,
      this.visible = true,
      this.onChildSelected,
      this.repository});
  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  late final GrowthRepository repo = widget.repository ?? GrowthRepository();
  List<Map<String, Object?>> children = [];
  List<Map<String, Object?>> records = [];
  int? selectedId;
  int indicator = 0;
  bool loading = true;
  String? error;
  int loadRequest = 0;

  @override
  void initState() {
    super.initState();
    selectedId = widget.initialChildId;
    load();
  }

  @override
  void didUpdateWidget(covariant GrowthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialChildId != oldWidget.initialChildId ||
        (widget.visible && !oldWidget.visible)) {
      if (widget.initialChildId != null) selectedId = widget.initialChildId;
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
          : (list.isEmpty ? null : list.first['id'] as int);
      final entries = id == null
          ? <Map<String, Object?>>[]
          : await repo.measurements(widget.ownerId, id);
      if (!mounted || request != loadRequest) return;
      setState(() {
        children = list;
        selectedId = id;
        records = entries;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted && request == loadRequest)
        setState(() {
          loading = false;
          error = 'Could not load growth data on this device.';
        });
    }
  }

  Future<void> addMeasurement() async {
    final height = TextEditingController();
    final weight = TextEditingController();
    DateTime date = DateUtils.dateOnly(DateTime.now());
    String method = 'standing';
    final child = children.firstWhere((c) => c['id'] == selectedId);
    final birth = DateTime.parse(child['birth'] as String);
    final route = DialogRoute<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Add measurement'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: birth,
                              lastDate: DateTime.now(),
                              initialDate: date);
                          if (d != null) update(() => date = d);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dateText(date))),
                    TextField(
                        controller: height,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Height or length (cm)')),
                    TextField(
                        controller: weight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Weight (kg)')),
                    DropdownButtonFormField<String>(
                        initialValue: method,
                        decoration:
                            const InputDecoration(labelText: 'Measured'),
                        items: const [
                          DropdownMenuItem(
                              value: 'standing', child: Text('Standing')),
                          DropdownMenuItem(
                              value: 'lying', child: Text('Lying down'))
                        ],
                        onChanged: (v) => update(() => method = v!)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
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
                                        'Enter valid positive measurements and a date after birth.')));
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('Save'))
                  ],
                )));
    final result = await Navigator.of(context).push(route);
    await route.completed;
    if (result == true) {
      try {
        await repo.addMeasurement(widget.ownerId, selectedId!, dateText(date),
            double.parse(height.text), double.parse(weight.text), method);
        await load();
      } catch (_) {
        showError();
      }
    }
    height.dispose();
    weight.dispose();
  }

  void showError() {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')));
  }

  String dateText(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const green = Color(0xFF1DA270);
  static const labels = ['Height-for-Age', 'BMI-for-Age'];

  @override
  Widget build(BuildContext context) {
    final child = selectedId == null || children.isEmpty
        ? null
        : children.where((c) => c['id'] == selectedId).firstOrNull;
    return ColoredBox(
      color: const Color(0xFFF4F5F9),
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            color: green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              const Icon(Icons.show_chart, color: Colors.white),
              const SizedBox(width: 16),
              const Expanded(
                  child: Text('Growth Chart',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold))),
              IconButton(
                color: Colors.white,
                tooltip: 'About this chart',
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('About growth charts'),
                          content: const Text(
                              'Growth is assessed using a child’s age, measurements and appropriate reference data. The WHO chart and calculations are still being prepared. Speak with a healthcare professional about any concerns.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'))
                          ],
                        )),
              ),
            ]),
          ),
          Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              Text(error!),
                              TextButton(
                                  onPressed: load,
                                  child: const Text('Try again'))
                            ]))
                      : ListView(padding: const EdgeInsets.all(14), children: [
                          Row(children: [
                            Expanded(
                                child: children.isEmpty
                                    ? const Text(
                                        'Add a child on the Home page to get started.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600))
                                    : DropdownButtonFormField<int>(
                                        key: ValueKey(selectedId),
                                        initialValue: children.any(
                                                (c) => c['id'] == selectedId)
                                            ? selectedId
                                            : null,
                                        decoration: const InputDecoration(
                                            labelText: 'Selected child',
                                            border: OutlineInputBorder(),
                                            isDense: true),
                                        items: children
                                            .map((c) => DropdownMenuItem(
                                                value: c['id'] as int,
                                                child:
                                                    Text(c['name'] as String)))
                                            .toList(),
                                        onChanged: (id) {
                                          setState(() {
                                            selectedId = id;
                                            records = [];
                                          });
                                          if (id != null)
                                            widget.onChildSelected?.call(id);
                                          load();
                                        },
                                      )),
                          ]),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                    labels.length,
                                    (i) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
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
                                                  fontWeight: FontWeight.w600),
                                              onSelected: (_) => setState(
                                                  () => indicator = i)),
                                        )),
                              )),
                          const SizedBox(height: 12),
                          Card(
                              color: Colors.white,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(labels[indicator],
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                          height: 245,
                                          width: double.infinity,
                                          child: Stack(children: [
                                            Positioned.fill(
                                                child: CustomPaint(
                                                    painter: _GridPainter())),
                                            Center(
                                                child: Container(
                                              margin: const EdgeInsets.all(24),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.95),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text(
                                                  child == null
                                                      ? 'Select or add a child to get started.'
                                                      : 'WHO references and results are not connected yet.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Colors.black54)),
                                            )),
                                          ])),
                                      const SizedBox(height: 12),
                                      const Row(children: [
                                        Icon(Icons.circle,
                                            color: green, size: 12),
                                        SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                'Measurements will appear here when the chart is ready',
                                                style: TextStyle(fontSize: 12)))
                                      ]),
                                      const SizedBox(height: 6),
                                      const Text(
                                          'WHO reference data not loaded yet',
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12)),
                                    ]),
                              )),
                          const SizedBox(height: 12),
                          Card(
                              color: const Color(0xFFFFF1F2),
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${labels[indicator]} Z-score',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Not available yet',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const Text(
                                          'Results will appear when WHO calculations are available.',
                                          style:
                                              TextStyle(color: Colors.black54)),
                                    ]),
                              )),
                          const SizedBox(height: 16),
                          Row(children: [
                            const Expanded(
                                child: Text('Measurement History',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold))),
                            TextButton.icon(
                                onPressed:
                                    child == null ? null : addMeasurement,
                                icon: const Icon(Icons.add),
                                label: const Text('Add')),
                          ]),
                          if (child == null)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('Select or add a child first.'))
                          else if (records.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('No measurements yet.'))
                          else
                            ...records.map((r) => Card(
                                color: Colors.white,
                                elevation: 0,
                                child: ListTile(
                                  title: Text(r['date'] as String),
                                  subtitle: Text(
                                      '${r['height']} cm  •  ${r['weight']} kg  •  ${r['method'] == 'lying' ? 'lying down' : 'standing'}'),
                                ))),
                        ])),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFE2E4E8)
      ..strokeWidth = 1;
    for (var i = 0; i <= 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
