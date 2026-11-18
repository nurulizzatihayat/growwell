import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'database.dart';

class HomeScreen extends StatefulWidget {
  final String ownerId;
  final ValueChanged<int> onNavigate;

  const HomeScreen({
    super.key,
    required this.ownerId,
    required this.onNavigate,
  });

  static const Color headerBlue = Color(0xFF1E88E5);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GrowthRepository repo = GrowthRepository();

  List<Map<String, Object?>> children = [];
  Map<String, Object?>? selectedChild;
  Map<String, Object?>? latestMeasurement;

  bool loading = true;
  bool saving = false;
  String? error;
  double? haz;

  @override
  void initState() {
    super.initState();
    loadChildren();
  }

  Future<void> loadChildren({String? selectId}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await repo.children(widget.ownerId);

      result.sort(
        (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
          (b['name'] ?? '').toString().toLowerCase(),
        ),
      );

      Map<String, Object?>? current;

      if (result.isNotEmpty) {
        current = result.firstWhere(
          (c) => c['id'] == selectId,
          orElse: () => result.firstWhere(
            (c) => c['id'] == selectedChild?['id'],
            orElse: () => result.first,
          ),
        );
      }

      List<Map<String, Object?>> measurements = [];

      if (current != null) {
        measurements = await repo.measurements(
          widget.ownerId,
          current['id'].toString(),
        );
      }

      measurements.sort((a, b) {
        final dateA =
            DateTime.tryParse((a['date'] ?? '').toString()) ?? DateTime(1900);

        final dateB =
            DateTime.tryParse((b['date'] ?? '').toString()) ?? DateTime(1900);

        return dateB.compareTo(dateA);
      });

      final newest = measurements.isNotEmpty ? measurements.first : null;

      double? calculatedHaz;

      if (current != null && newest != null) {
        final height = (newest['height'] as num?)?.toDouble();

        if (height != null && height > 0) {
          final csv = await rootBundle.loadString(
            'assets/who/growth_curves.csv',
          );

          calculatedHaz = calculateHaz(csv, current, height);
        }
      }

      if (!mounted) return;

      setState(() {
        children = result;
        selectedChild = current;
        latestMeasurement = newest;
        haz = calculatedHaz;
        loading = false;
      });
    } catch (e) {
      debugPrint('Growth load failed: $e');

      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  double? calculateHaz(String csv, Map<String, Object?> child, double height) {
    final birth = DateTime.tryParse((child['birth'] ?? '').toString());

    if (birth == null) return null;

    final now = DateTime.now();

    final months = (now.year - birth.year) * 12 + now.month - birth.month;

    if (months < 0 || months > 228) return null;

    final sex = (child['sex'] ?? '').toString().toLowerCase();

    final tableSex = sex == 'boy' || sex == 'male' ? 'boys' : 'girls';

    final year = months <= 60 ? '2006' : '2007';

    final rows = csv.split(RegExp(r'\r?\n'));

    for (final line in rows) {
      final r = line.split(',');

      if (r.length < 11) continue;

      if (r[0].trim() != 'height') continue;
      if (r[1].trim() != tableSex) continue;
      if (r[2].trim() != year) continue;

      final month = int.tryParse(r[3].trim());

      if (month != months) continue;

      final sd = r
          .sublist(4, 11)
          .map((v) => double.tryParse(v.trim()))
          .toList();

      if (sd.any((v) => v == null)) return null;

      final values = sd.cast<double>();

      if (height <= values.first) {
        return -3;
      }

      if (height >= values.last) {
        return 3;
      }

      for (int i = 0; i < values.length - 1; i++) {
        if (height >= values[i] && height <= values[i + 1]) {
          final fraction = (height - values[i]) / (values[i + 1] - values[i]);

          return (i - 3) + fraction;
        }
      }
    }

    return null;
  }

  String get ageText {
    if (selectedChild == null) return '';

    final birth = DateTime.tryParse((selectedChild!['birth'] ?? '').toString());

    if (birth == null) return 'Age unavailable';

    final now = DateTime.now();

    int months = (now.year - birth.year) * 12 + now.month - birth.month;

    if (now.day < birth.day) months--;

    if (months < 0) return 'Age unavailable';

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    return '$years years $remainingMonths months';
  }

  GrowthStatus get growthStatus {
    if (haz == null) return GrowthStatus.normal;

    if (haz! < -3) {
      return GrowthStatus.severeStunting;
    }

    if (haz! < -2) {
      return GrowthStatus.stunting;
    }

    return GrowthStatus.normal;
  }

  Future<void> openChildDialog({Map<String, Object?>? existing}) async {
    final nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );

    DateTime? birth = existing == null
        ? null
        : DateTime.tryParse(existing['birth']?.toString() ?? '');

    String sex = existing?['sex']?.toString() ?? 'boy';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Child' : 'Edit Child'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Child's name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: Text(
                        birth == null
                            ? 'Select date of birth'
                            : '${birth!.day}/${birth!.month}/${birth!.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: birth ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            birth = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sex,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'boy', child: Text('Boy')),
                        DropdownMenuItem(value: 'girl', child: Text('Girl')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            sex = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty || birth == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter the name and date of birth.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'name': nameController.text.trim(),
                      'birth':
                          '${birth!.year}-${birth!.month.toString().padLeft(2, '0')}-${birth!.day.toString().padLeft(2, '0')}',
                      'sex': sex,
                    });
                  },
                  child: Text(existing == null ? 'Add Child' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == null || !mounted) return;

    setState(() => saving = true);

    try {
      if (existing == null) {
        final newId = await repo.addChild(
          widget.ownerId,
          result['name'],
          result['birth'],
          result['sex'],
        );

        await loadChildren(selectId: newId);
      } else {
        await repo.updateChild(
          widget.ownerId,
          existing['id'].toString(),
          result['name'],
          result['birth'],
          result['sex'],
        );

        await loadChildren(selectId: existing['id'].toString());
      }
    } catch (e) {
      debugPrint('Child save failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to save child: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget addChildCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: saving ? null : () => openChildDialog(),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE3F0FD),
                child: Icon(
                  Icons.person_add_alt_1,
                  color: HomeScreen.headerBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Child',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Add another child to monitor their growth.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: HomeScreen.headerBlue),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.headerBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 42,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Unable to load growth data.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: loadChildren,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (children.isNotEmpty) ...[
                              const Text(
                                'Select Child',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: children.map((c) {
                                  final selected =
                                      c['id'] == selectedChild?['id'];

                                  return ChoiceChip(
                                    label: Text(
                                      c['name']?.toString() ?? 'Child',
                                    ),
                                    selected: selected,
                                    onSelected: (_) {
                                      loadChildren(
                                        selectId: c['id'].toString(),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              ProfileCard(
                                name: selectedChild?['name']?.toString() ?? '',
                                age: ageText,
                                gender: selectedChild?['sex']?.toString() ?? '',
                                onEditPressed: () {
                                  openChildDialog(existing: selectedChild);
                                },
                              ),
                            ] else ...[
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'You have not added a child yet.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            addChildCard(),

                            if (selectedChild != null) ...[
                              const SizedBox(height: 24),
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MeasurementTile(
                                        label: 'Height',
                                        value:
                                            latestMeasurement?['height'] == null
                                            ? '--'
                                            : '${(latestMeasurement!['height'] as num).toStringAsFixed(1)} cm',
                                        subtitle: 'Latest',
                                      ),
                                    ),
                                    const VerticalDivider(width: 1),
                                    Expanded(
                                      child: MeasurementTile(
                                        label: 'Weight',
                                        value:
                                            latestMeasurement?['weight'] == null
                                            ? '--'
                                            : '${(latestMeasurement!['weight'] as num).toStringAsFixed(1)} kg',
                                        subtitle: 'Latest',
                                      ),
                                    ),
                                    const VerticalDivider(width: 1),
                                    Expanded(
                                      child: MeasurementTile(
                                        label: 'BMI',
                                        value:
                                            latestMeasurement?['height'] ==
                                                    null ||
                                                latestMeasurement?['weight'] ==
                                                    null
                                            ? '--'
                                            : ((latestMeasurement!['weight']
                                                              as num)
                                                          .toDouble() /
                                                      (((latestMeasurement!['height']
                                                                      as num)
                                                                  .toDouble() /
                                                              100) *
                                                          ((latestMeasurement!['height']
                                                                      as num)
                                                                  .toDouble() /
                                                              100)))
                                                  .toStringAsFixed(1),
                                        subtitle: 'Calculated',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Growth Status (Height-for-Age)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (haz != null)
                                GrowthStatusCard(
                                  title: growthStatus.title,
                                  zScoreText:
                                      'Height-for-Age Z-score (HAZ): ${haz!.toStringAsFixed(1)}',
                                  rangeText: growthStatus.rangeText,
                                  color: growthStatus.color,
                                )
                              else
                                const Text(
                                  'Growth status is unavailable. Check the birth date, measurement and WHO growth data.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              const SizedBox(height: 12),
                              const RecommendedActionCard(
                                message: 'Provide nutritious meals and monitor growth regularly. Consult a healthcare professional for further assessment.',
                              ),
                              const SizedBox(height: 20),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                children: [
                                  QuickActionButton(
                                    label: 'Growth Chart',
                                    icon: Icons.bar_chart,
                                    color: const Color(0xFF1E88E5),
                                    onTap: () => widget.onNavigate(1),
                                  ),
                                  QuickActionButton(
                                    label: 'Meal Plan',
                                    icon: Icons.restaurant,
                                    color: const Color(0xFF2EA862),
                                    onTap: () => widget.onNavigate(2),
                                  ),
                                  QuickActionButton(
                                    label: 'Nutrition Tips',
                                    icon: Icons.list_alt,
                                    color: const Color(0xFFFF6A2B),
                                    onTap: () => widget.onNavigate(2),
                                  ),
                                  QuickActionButton(
                                    label: 'Healthy Recipes',
                                    icon: Icons.menu_book,
                                    color: const Color(0xFF7E57C2),
                                    onTap: () => widget.onNavigate(3),
                                  ),
                                  QuickActionButton(
                                    label: 'Record Data',
                                    icon: Icons.edit_calendar,
                                    color: const Color(0xFFE8456B),
                                    onTap: () => widget.onNavigate(1),
                                  ),
                                  QuickActionButton(
                                    label: 'Settings',
                                    icon: Icons.settings,
                                    color: const Color(0xFF607D8B),
                                    onTap: () => widget.onNavigate(4),
                                  ),
                                ],
                              ),
                            ],
                            if (saving)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.eco, color: HomeScreen.headerBlue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'siCILIK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Aplikasi untuk melihat progres anak anda!',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

enum GrowthStatus {
  normal(
    'Normal Growth',
    'Within normal range (HAZ ≥ -2 SD)',
    Color(0xFF2E9E5B),
  ),
  stunting(
    'Stunting Detected',
    'Below -2 SD (Stunting range)',
    Color(0xFFD32F2F),
  ),
  severeStunting(
    'Severe Stunting Detected',
    'Below -3 SD (Severe stunting range)',
    Color(0xFFB71C1C),
  );

  final String title;
  final String rangeText;
  final Color color;

  const GrowthStatus(this.title, this.rangeText, this.color);
}

// child profile

class ChildProfile {
  final String name;
  final int ageYears;
  final int ageMonths;
  final String gender;
  final double heightCm;
  final double weightKg;
  final double haz; // Height-for-Age Z-score

  const ChildProfile({
    required this.name,
    required this.ageYears,
    required this.ageMonths,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.haz,
  });

  // Temporary sample data, matching the design
  static const ChildProfile adam = ChildProfile(
    name: 'Adam',
    ageYears: 4,
    ageMonths: 2,
    gender: 'Boy',
    heightCm: 92.0,
    weightKg: 13.5,
    haz: -2.4,
  );

  String get ageText => '$ageYears years $ageMonths months';

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  GrowthStatus get status {
    if (haz < -3) return GrowthStatus.severeStunting;
    if (haz < -2) return GrowthStatus.stunting;
    return GrowthStatus.normal;
  }
}

//growthstatuscard

class GrowthStatusCard extends StatelessWidget {
  final String title;
  final String zScoreText;
  final String rangeText;
  final Color color;

  const GrowthStatusCard({
    super.key,
    required this.title,
    required this.zScoreText,
    required this.rangeText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.accessibility_new, size: 44, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  zScoreText,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                Text(rangeText),
              ],
            ),
          ),
          Icon(Icons.info, size: 20, color: color),
        ],
      ),
    );
  }
}

//measurement tile

class MeasurementTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color? badgeColor; // if set, the subtitle is shown as a colored pill

  const MeasurementTile({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor!.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
      ],
    );
  }
}

//quick action button

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//recommended action card

class RecommendedActionCard extends StatelessWidget {
  final String message;

  const RecommendedActionCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1CC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3DC9A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 40,
            color: Color(0xFFE0A100),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Action',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//profile card

class ProfileCard extends StatelessWidget {
  final String name;
  final String age;
  final String gender;
  final VoidCallback? onEditPressed;

  const ProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFD6E6F7),
          // Placeholder. Swap for backgroundImage: AssetImage('assets/adam.png') later.
          child: Icon(Icons.person, size: 40, color: Color(0xFF1E88E5)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(age, style: const TextStyle(color: Colors.black54)),
              Text(gender, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onEditPressed,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit Profile'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            backgroundColor: const Color(0xFFE3F0FD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
