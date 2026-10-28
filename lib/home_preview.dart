import 'package:flutter/material.dart';
import 'growth_repository.dart';

class HomePage extends StatefulWidget {
  final String ownerId;
  final bool visible;
  final int? selectedChildId;
  final ValueChanged<int> onNavigate;
  final ValueChanged<int> onChildSelected;
  final GrowthRepository? repository;
  const HomePage(
      {super.key,
      required this.ownerId,
      required this.visible,
      this.selectedChildId,
      required this.onNavigate,
      required this.onChildSelected,
      this.repository});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GrowthRepository repo = widget.repository ?? GrowthRepository();
  List<Map<String, Object?>> children = [];
  Map<String, Object?>? selected;
  List<Map<String, Object?>> measurements = [];
  bool loading = true;
  String? error;
  String? caregiverName;
  int request = 0;
  int? pendingChildId;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedChildId != oldWidget.selectedChildId &&
        widget.selectedChildId != null) {
      final matches =
          children.where((child) => child['id'] == widget.selectedChildId);
      selected = matches.isEmpty ? null : matches.first;
      pendingChildId = widget.selectedChildId;
    }
    if (widget.visible && !oldWidget.visible) reload();
  }

  Future<void> reload() async {
    final current = ++request;
    try {
      final list = await repo.children(widget.ownerId);
      final name = await repo.profileName(widget.ownerId);
      final matches =
          list.where((c) => c['id'] == (pendingChildId ?? selected?['id']));
      final child = matches.isEmpty ? null : matches.first;
      final entries = child == null
          ? <Map<String, Object?>>[]
          : await repo.measurements(widget.ownerId, child['id'] as int);
      if (!mounted || current != request) return;
      setState(() {
        children = list;
        caregiverName = name;
        selected = child;
        pendingChildId = null;
        measurements = entries;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted || current != request) return;
      setState(() {
        loading = false;
        error = 'Could not load your children. Please try again.';
      });
    }
  }

  Future<void> selectChild(Map<String, Object?> child) async {
    final id = child['id'] as int;
    widget.onChildSelected(id);
    setState(() {
      selected = child;
      measurements = [];
    });
    await reload();
  }

  Future<void> editChild({Map<String, Object?>? child}) async {
    final name = TextEditingController(text: child?['name'] as String? ?? '');
    DateTime? birth =
        child == null ? null : DateTime.parse(child['birth'] as String);
    String? sex = child?['sex'] as String?;
    final route = DialogRoute<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: Text(child == null ? 'Add a child' : 'Edit profile'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Child’s name')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue: sex,
                        decoration: const InputDecoration(
                            labelText: 'Sex for growth reference'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Boy')),
                          DropdownMenuItem(value: 'female', child: Text('Girl'))
                        ],
                        onChanged: (v) => update(() => sex = v)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(birth == null
                            ? 'Select date of birth'
                            : dateText(birth!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              initialDate: birth ?? DateTime.now());
                          if (d != null) update(() => birth = d);
                        }),
                    const Text('Age is calculated from the date of birth.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (name.text.trim().isEmpty ||
                              birth == null ||
                              sex == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Enter a name, sex and date of birth.')));
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('Save'))
                  ],
                )));
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    final childName = name.text.trim();
    name.dispose();
    if (saved == true && birth != null && sex != null) {
      try {
        if (child == null) {
          await repo.addChild(
              widget.ownerId, childName, dateText(birth!), sex!);
        } else {
          await repo.updateChild(widget.ownerId, child['id'] as int, childName,
              dateText(birth!), sex!);
        }
        await reload();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not save the profile. Please try again.')));
      }
    }
  }

  String dateText(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String ageText(DateTime birth) {
    final now = DateTime.now();
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 0) return 'Age unavailable';
    return '${months ~/ 12} years ${months % 12} months';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1684D2);
    final latest = measurements.isEmpty ? null : measurements.first;
    final h = (latest?['height'] as num?)?.toDouble();
    final w = (latest?['weight'] as num?)?.toDouble();
    final bmi = h != null && h > 0 && w != null
        ? (w / ((h / 100) * (h / 100))).toStringAsFixed(1)
        : '—';
    return ColoredBox(
        color: const Color(0xFFF4F5F9),
        child: SafeArea(
            child: Column(children: [
          Container(
              color: blue,
              padding: const EdgeInsets.all(20),
              child: const Row(children: [
                CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.spa, color: blue)),
                SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('GrowWell',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      Text('Healthy Growth, Brighter Future',
                          style: TextStyle(color: Colors.white))
                    ]))
              ])),
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
                                  onPressed: reload,
                                  child: const Text('Try again'))
                            ]))
                      : ListView(padding: const EdgeInsets.all(16), children: [
                          if (selected == null) ...[
                            Text(
                                caregiverName?.trim().isNotEmpty == true
                                    ? 'Welcome, ${caregiverName!.trim()}!'
                                    : 'Welcome!',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(children: [
                              const Expanded(
                                  child: Text('Your children',
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.bold))),
                              if (children.isNotEmpty)
                                FilledButton.icon(
                                    onPressed: () => editChild(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add child'))
                            ]),
                            const SizedBox(height: 16),
                            if (children.isEmpty)
                              Card(
                                  color: Colors.white,
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(children: [
                                        Icon(Icons.child_care,
                                            color: blue, size: 42),
                                        const SizedBox(height: 12),
                                        const Text('Welcome to GrowWell',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Add a child to start recording measurements and tracking growth.',
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                            onPressed: () => editChild(),
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                                'Add your first child'))
                                      ])))
                            else
                              ...children.map((child) => Card(
                                  color: Colors.white,
                                  child: ListTile(
                                      leading: const CircleAvatar(
                                          child: Icon(Icons.child_care)),
                                      title: Text(child['name'] as String),
                                      subtitle: Text(ageText(DateTime.parse(
                                          child['birth'] as String))),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => selectChild(child)))),
                          ] else ...[
                            Card(
                                color: Colors.white,
                                elevation: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      Row(children: [
                                        IconButton(
                                            tooltip: 'Back to children',
                                            onPressed: () => setState(() {
                                                  selected = null;
                                                  measurements = [];
                                                  pendingChildId = null;
                                                }),
                                            icon: const Icon(Icons.arrow_back)),
                                        const CircleAvatar(
                                            radius: 29,
                                            backgroundColor: Color(0xFFE4F1F8),
                                            child: Icon(Icons.child_care,
                                                color: blue, size: 30)),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(selected!['name'] as String,
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(ageText(DateTime.parse(
                                                  selected!['birth']
                                                      as String))),
                                              Text(selected!['sex'] == 'male'
                                                  ? 'Boy'
                                                  : 'Girl')
                                            ])),
                                      ]),
                                      Align(alignment: Alignment.centerRight, child: TextButton.icon(
                                            onPressed: () =>
                                                editChild(child: selected),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 16),
                                            label: const Text('Edit Profile'))),
                                      const SizedBox(height: 20),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Expanded(child: _Metric(
                                                'Height',
                                                h == null
                                                    ? '—'
                                                    : '${h.toStringAsFixed(1)} cm')),
                                            Expanded(child: _Metric(
                                                'Weight',
                                                w == null
                                                    ? '—'
                                                    : '${w.toStringAsFixed(1)} kg')),
                                            Expanded(child: _Metric('BMI', bmi))
                                          ]),
                                      const SizedBox(height: 10),
                                      Text(
                                          latest == null
                                              ? 'No measurements yet'
                                              : 'Last measured ${latest['date']}',
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12)),
                                    ]))),
                            const SizedBox(height: 16),
                            const Text('Growth Status (Height-for-Age)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 8),
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Row(children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange),
                                  SizedBox(width: 12),
                                  Expanded(
                                      child: Text(
                                          'Growth assessment is not available yet.'))
                                ])),
                            const SizedBox(height: 14),
                            GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.15,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: [
                                  _Shortcut('Growth Chart', Icons.show_chart,
                                      Colors.blue, () => widget.onNavigate(1)),
                                  _Shortcut('Meal Plan', Icons.restaurant,
                                      Colors.green, () => widget.onNavigate(2)),
                                  _Shortcut(
                                      'Nutrition Tips',
                                      Icons.list_alt,
                                      Colors.deepOrange,
                                      () => widget.onNavigate(2)),
                                  _Shortcut(
                                      'Healthy Recipes',
                                      Icons.menu_book,
                                      Colors.deepPurple,
                                      () => widget.onNavigate(3)),
                                  _Shortcut('Record Data', Icons.calendar_month,
                                      Colors.pink, () => widget.onNavigate(1)),
                                  _Shortcut(
                                      'Settings',
                                      Icons.settings,
                                      Colors.blueGrey,
                                      () => widget.onNavigate(4)),
                                ]),
                          ],
                        ])),
        ])));
  }
}

class _Metric extends StatelessWidget {
  final String title, value;
  const _Metric(this.title, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
      ]);
}

class _Shortcut extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Shortcut(this.title, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Card(
      color: Colors.white,
      elevation: 0,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white)),
            const SizedBox(height: 5),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12))
          ])));
}
