import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color mealOrange = Color(0xFFF39C12);
const Color mealAmber = Color(0xFFFFB41F);
const Color mealPanel = Color(0xFFF4F6FB);
const Color mealChip = Color(0xFFEEF1F8);
const Color mealPurple = Color(0xFF6D4FC2);
const Color mealText = Color(0xFF1F2430);
const Color mealMuted = Color(0xFF8A94A6);

class MealItem {
  final String slot;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String name;
  final String emoji;
  final Color tileColor;

  /// Optional photo. Leave null to show the emoji tile. If you later add photos
  /// (and declare them under `assets:` in pubspec.yaml), set e.g.
  /// 'assets/meals/breakfast.jpg' here.
  final String? imageAsset;
  final double energy; // kcal
  final double protein; // g
  final double calcium; // mg
  final double iron; // mg
  final List<String> shopping;

  const MealItem({
    required this.slot,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.emoji,
    required this.tileColor,
    this.imageAsset,
    required this.energy,
    required this.protein,
    required this.calcium,
    required this.iron,
    required this.shopping,
  });
}

// Static sample data copied from the reference design. There is no meal-plan
// table in database.dart, so nothing here is read from or written to SQLite.
const List<MealItem> mealPlanItems = [
  MealItem(
    slot: 'Breakfast',
    time: '7:00 AM',
    icon: Icons.wb_sunny_rounded,
    iconColor: mealOrange,
    name: 'Oats with milk, banana and egg',
    emoji: '🥣',
    tileColor: Color(0xFFFFF1D6),
    energy: 320,
    protein: 14,
    calcium: 280,
    iron: 2.1,
    shopping: ['Rolled oats', 'Fresh milk', 'Banana', 'Eggs'],
  ),
  MealItem(
    slot: 'Lunch',
    time: '12:00 PM',
    icon: Icons.wb_sunny_rounded,
    iconColor: mealOrange,
    name: 'Rice, ikan kembung and vegetables',
    emoji: '🍚🐟',
    tileColor: Color(0xFFE3F1DC),
    energy: 420,
    protein: 24,
    calcium: 180,
    iron: 2.8,
    shopping: ['Rice', 'Ikan kembung', 'Mixed vegetables'],
  ),
  MealItem(
    slot: 'Snack',
    time: '4:00 PM',
    icon: Icons.local_florist_rounded,
    iconColor: mealPurple,
    name: 'Yogurt with fruit',
    emoji: '🍓',
    tileColor: Color(0xFFFDE3E6),
    energy: 180,
    protein: 8,
    calcium: 220,
    iron: 0.7,
    shopping: ['Plain yogurt', 'Seasonal fruit'],
  ),
  MealItem(
    slot: 'Dinner',
    time: '7:00 PM',
    icon: Icons.nightlight_round,
    iconColor: mealPurple,
    name: 'Chicken soup, rice and vegetables',
    emoji: '🍲',
    tileColor: Color(0xFFFFE9CC),
    energy: 350,
    protein: 22,
    calcium: 150,
    iron: 2.1,
    shopping: ['Chicken', 'Rice', 'Mixed vegetables'],
  ),
];

const List<String> _mealWeekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _mealMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _mealDateLabel(DateTime d) =>
    '${_mealWeekdays[d.weekday - 1]}, ${d.day} ${_mealMonths[d.month - 1]} ${d.year}';

String _mealNum(double v) {
  final fixed = v.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

class MealPlanPage extends StatefulWidget {
  /// Called when the back arrow is tapped.
  final VoidCallback? onBack;

  const MealPlanPage({super.key, this.onBack});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  static const List<String> _tabs = [
    'Daily Plan',
    'Nutrient Intake',
    'Shopping List',
  ];

  late DateTime _date;
  int _tab = 0;
  final Set<String> _bought = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  void _shiftDay(int days) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + days);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: mealOrange),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: mealOrange,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  color: mealPanel,
                  child: Column(
                    children: [
                      _buildControls(),
                      Expanded(child: _buildTabContent()),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.dinner_dining_rounded, color: mealOrange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelan Makanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pelan khas untuk anak anda',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            tooltip: 'Pick date',
            onPressed: _pickDate,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: mealOrange,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: mealChip,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _shiftDay(-1),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: mealText,
                    size: 28,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: mealText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _mealDateLabel(_date),
                          style: const TextStyle(
                            color: mealText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _shiftDay(1),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: mealText,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _buildTab(i)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final selected = _tab == index;
    return Material(
      color: selected ? mealAmber : mealChip,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _tab = index),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _tabs[index],
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : mealText,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 1:
        return _buildNutrientIntake();
      case 2:
        return _buildShoppingList();
      default:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [for (final meal in mealPlanItems) MealCard(meal: meal)],
        );
    }
  }

  Widget _buildNutrientIntake() {
    double sum(double Function(MealItem m) pick) =>
        mealPlanItems.fold<double>(0, (total, m) => total + pick(m));

    final stats = <_NutrientStat>[
      _NutrientStat(
        'Energy',
        _mealNum(sum((m) => m.energy)),
        'kcal',
        Icons.local_fire_department_rounded,
      ),
      _NutrientStat(
        'Protein',
        _mealNum(sum((m) => m.protein)),
        'g',
        Icons.egg_alt_rounded,
      ),
      _NutrientStat(
        'Calcium',
        _mealNum(sum((m) => m.calcium)),
        'mg',
        Icons.water_drop_rounded,
      ),
      _NutrientStat(
        'Iron',
        _mealNum(sum((m) => m.iron)),
        'mg',
        Icons.bloodtype_rounded,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          'Total for ${_mealDateLabel(_date)}',
          style: const TextStyle(
            color: mealText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _NutrientTile(stat: stats[0])),
            const SizedBox(width: 12),
            Expanded(child: _NutrientTile(stat: stats[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _NutrientTile(stat: stats[2])),
            const SizedBox(width: 12),
            Expanded(child: _NutrientTile(stat: stats[3])),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Added up from the ${mealPlanItems.length} meals in your daily plan.',
          style: const TextStyle(color: mealMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildShoppingList() {
    // Unique ingredients, in the order they first appear in the plan.
    final items = <String>{for (final meal in mealPlanItems) ...meal.shopping}
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (final item in items)
                CheckboxListTile(
                  activeColor: mealOrange,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _bought.contains(item),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _bought.add(item);
                      } else {
                        _bought.remove(item);
                      }
                    });
                  },
                  title: Text(
                    item,
                    style: TextStyle(
                      color: mealText,
                      fontWeight: FontWeight.w600,
                      decoration: _bought.contains(item)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ingredients needed for the meals in your daily plan.',
          style: TextStyle(color: mealMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  final MealItem meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meal.icon, color: meal.iconColor, size: 22),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: meal.slot,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' (${meal.time})',
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                style: const TextStyle(color: mealText, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPicture(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        color: mealText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bullet('Energy: ${_mealNum(meal.energy)} kcal'),
                    _bullet('Protein: ${_mealNum(meal.protein)} g'),
                    _bullet('Calcium: ${_mealNum(meal.calcium)} mg'),
                    _bullet('Iron: ${_mealNum(meal.iron)} mg'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicture() {
    final emojiTile = Container(
      color: meal.tileColor,
      alignment: Alignment.center,
      child: Text(meal.emoji, style: const TextStyle(fontSize: 44)),
    );

    final asset = meal.imageAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 136,
        height: 104,
        child: asset == null
            ? emojiTile
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => emojiTile,
              ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: mealText, fontSize: 13, height: 1.3),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: mealText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientStat {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _NutrientStat(this.label, this.value, this.unit, this.icon);
}

class _NutrientTile extends StatelessWidget {
  final _NutrientStat stat;

  const _NutrientTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: mealOrange, size: 24),
          const SizedBox(height: 10),
          Text(
            stat.label,
            style: const TextStyle(color: mealMuted, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: stat.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' ${stat.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            style: const TextStyle(color: mealText),
          ),
        ],
      ),
    );
  }
}
