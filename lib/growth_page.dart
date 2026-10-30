import 'package:flutter/material.dart';
import 'growth_repository.dart';
import 'height_chart.dart';
import 'who_height_reference.dart';

class GrowthPage extends StatefulWidget {
  final String ownerId;
  final int? initialChildId;
  final bool visible;
  final ValueChanged<int>? onChildSelected;
  final GrowthRepository? repository;
  final Future<WhoHeightReference>? heightReference;
  const GrowthPage(
      {super.key,
      required this.ownerId,
      this.initialChildId,
      this.visible = true,
      this.onChildSelected,
      this.repository,
      this.heightReference});
  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  late final GrowthRepository repo = widget.repository ?? GrowthRepository();
  List<Map<String, Object?>> children = [];
  List<Map<String, Object?>> records = [];
  int? selectedId;
  int? selectedMeasurementId;
  int indicator = 0;
  bool showProgress = false;
  final ScrollController scrollController = ScrollController();
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
          : (list.isEmpty ? null : list.first['id'] as int);
      final entries = id == null
          ? <Map<String, Object?>>[]
          : await repo.measurements(widget.ownerId, id);
      if (!mounted || request != loadRequest) return;
      setState(() {
        if (selectedId != id ||
            !entries.any((entry) => entry['id'] == selectedMeasurementId)) {
          selectedMeasurementId =
              entries.isEmpty ? null : entries.first['id'] as int;
        }
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
                        value: method,
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
        selectedMeasurementId = await repo.addMeasurement(
            widget.ownerId,
            selectedId!,
            dateText(date),
            double.parse(height.text),
            double.parse(weight.text),
            method);
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
            color: showProgress ? const Color(0xFF51409B) : green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              if (showProgress)
                IconButton(
                    tooltip: 'Back to growth chart',
                    onPressed: () => setState(() => showProgress = false),
                    icon: const Icon(Icons.arrow_back, color: Colors.white))
              else
                const Icon(Icons.show_chart, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(showProgress ? 'Growth Progress' : 'Growth Chart',
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
                              'Height-for-age uses WHO reference values. The result is a screening aid, not a diagnosis. Discuss concerns with a healthcare professional.'),
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
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(14),
                          children: [
                              Row(children: [
                                Expanded(
                                    child: children.isEmpty
                                        ? const Text(
                                            'Add a child on the Home page to get started.',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600))
                                        : DropdownButtonFormField<int>(
                                            key: ValueKey(selectedId),
                                            value: children.any((c) =>
                                                    c['id'] == selectedId)
                                                ? selectedId
                                                : null,
                                            decoration: const InputDecoration(
                                                labelText: 'Selected child',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            items: children
                                                .map((c) => DropdownMenuItem(
                                                    value: c['id'] as int,
                                                    child: Text(
                                                        c['name'] as String)))
                                                .toList(),
                                            onChanged: (id) {
                                              setState(() {
                                                selectedId = id;
                                                selectedMeasurementId = null;
                                                records = [];
                                              });
                                              if (id != null)
                                                widget.onChildSelected
                                                    ?.call(id);
                                              load();
                                            },
                                          )),
                              ]),
                              const SizedBox(height: 14),
                              if (!showProgress)
                                SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(
                                          labels.length,
                                          (i) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 6),
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
                                                        fontWeight:
                                                            FontWeight.w600),
                                                    onSelected: (_) => setState(
                                                        () => indicator = i)),
                                              )),
                                    )),
                              const SizedBox(height: 12),
                              if (indicator == 0)
                                HeightChart(
                                    child: child,
                                    records: records,
                                    selectedRecord: records
                                        .where((record) =>
                                            record['id'] ==
                                            selectedMeasurementId)
                                        .firstOrNull,
                                    progress: showProgress,
                                    reference: widget.heightReference)
                              else
                                const Card(
                                    child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                            'BMI-for-age chart and interpretation are not available yet.'))),
                              if (!showProgress &&
                                  indicator == 0 &&
                                  child != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: FilledButton.icon(
                                        onPressed: () {
                                          setState(() => showProgress = true);
                                          scrollController.animateTo(0,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeOut);
                                        },
                                        icon: const Icon(Icons.timeline),
                                        label: const Text(
                                            'View Growth Progress'))),
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
                                    label: const Text('Add measurement')),
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
                                      selected:
                                          r['id'] == selectedMeasurementId &&
                                              !showProgress,
                                      selectedTileColor:
                                          const Color(0xFFE3F5EB),
                                      onTap: () {
                                        setState(() {
                                          selectedMeasurementId =
                                              r['id'] as int;
                                          showProgress = false;
                                          indicator = 0;
                                        });
                                        scrollController.animateTo(0,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOut);
                                      },
                                      title: Text(r['date'] as String),
                                      subtitle: Text(
                                          'Age: ${measurementAge(DateTime.parse(child!['birth'] as String), DateTime.parse(r['date'] as String))}  •  ${r['height']} cm  •  ${r['weight']} kg'),
                                      trailing: const Icon(Icons.chevron_right),
                                    ))),
                            ])),
        ]),
      ),
    );
  }
}
