import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GrowWell());
}

const Color blush = Color(0xFFF7DCE4);
const Color rose = Color(0xFFB94E70);
const Color cream = Color(0xFFFFFAF5);
const Color ink = Color(0xFF302A2D);
const Color sage = Color(0xFFE7EFD9);

class GrowWell extends StatelessWidget {
  const GrowWell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowWell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: rose,
          surface: cream,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}


// Demo authentication flow.
// This validates form input locally; it does NOT create real accounts or
// securely authenticate users. Connect a backend such as Firebase Auth for that.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // AuthGate will automatically show MainNavigation.
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        message = 'Incorrect email or password.';
        break;
      case 'wrong-password':
        message = 'Incorrect email or password.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = e.message ?? 'Login failed. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 112,
                    decoration: BoxDecoration(
                      color: blush,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text('🥑 🫐 🍓', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in and check your children\'s growth progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  const Text('Email address',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _authDecoration(
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@') ||
                          !email.contains('.')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: _authDecoration(
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(_hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password.';
                      }
                      if (value.length < 6) {
                        return 'Use at least 6 characters for this demo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: rose,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Log in',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New here? ",
                          style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
                              color: rose, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  if (!_agreeToTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please agree to continue.'),
      ),
    );
    return;
  }

  try {
    // Create a real Firebase account.
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Account creation failed.');
    }

    // Save the profile in SQLite.
    await DatabaseHelper.saveProfile(
      uid: user.uid,
      name: _nameController.text.trim(),
      email: user.email ?? _emailController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! 💗'),
      ),
    );

    // Firebase signs the user in automatically after registration.
    // Signing out lets them return to the login page and sign in normally.
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = 'This email already has an account.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'weak-password':
        message = 'Please choose a stronger password.';
        break;
      default:
        message = e.message ?? 'Registration failed. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your account may have been created, but saving your profile failed. Please check your connection and try again.',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: cream, title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              const Text(
                'Join GrowWell',
                style: TextStyle(
                    color: ink, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to get started.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Text('Your name',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _authDecoration(
                    hint: 'What should we call you?',
                    icon: Icons.person_outline_rounded),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name.'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Email address',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _authDecoration(
                    hint: 'you@example.com',
                    icon: Icons.mail_outline_rounded),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@') ||
                      !email.contains('.')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: _authDecoration(
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Confirm password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: _authDecoration(
                    hint: 'Type your password again',
                    icon: Icons.lock_outline_rounded),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match.'
                    : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: rose,
                value: _agreeToTerms,
                onChanged: (value) =>
                    setState(() => _agreeToTerms = value ?? false),
                title: const Text(
                  'I agree to the app terms and privacy policy.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _register,
                style: FilledButton.styleFrom(
                  backgroundColor: rose,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Create account',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Already have an account? Log in',
                  style: TextStyle(color: rose, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _authDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: rose),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: rose, width: 1.5),
    ),
  );
}


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Opens on the Nutrition tab, which now shows the Personalised Meal Plan.
  int selectedIndex = 2;

  // Built on demand (not const) because the meal plan page needs a callback.
  List<Widget> get pages => [
        const PlaceholderPage(
          title: 'Home',
          subtitle: 'Your daily wellness overview will go here.',
          icon: Icons.home_rounded,
        ),
        const PlaceholderPage(
          title: 'Growth',
          subtitle: 'Track growth and progress here.',
          icon: Icons.trending_up_rounded,
        ),
        MealPlanPage(
          onBack: () => setState(() => selectedIndex = 0),
        ),
        const RecipesPage(),
        const PlaceholderPage(
          title: 'More',
          subtitle: 'Settings and extra features will go here.',
          icon: Icons.grid_view_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        selectedIndex: selectedIndex,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? mealOrange : mealMuted,
          );
        }),
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded, color: mealMuted),
            selectedIcon: Icon(Icons.home_rounded, color: mealOrange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded, color: mealMuted),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: mealOrange),
            label: 'Growth',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_rounded, color: mealMuted),
            selectedIcon: Icon(Icons.restaurant_rounded, color: mealOrange),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded, color: mealMuted),
            selectedIcon: Icon(Icons.menu_book_rounded, color: mealOrange),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded, color: mealMuted),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: mealOrange),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Personalised Meal Plan (shown on the "Nutrition" tab)
// ===========================================================================

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
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const List<String> _mealMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
            const Expanded(
              child: Text(
                'Personalised Meal Plan',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickDate,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.calendar_month_rounded,
                          color: mealOrange, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: mealText, size: 28),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: mealText),
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
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: mealText, size: 28),
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
          children: [
            for (final meal in mealPlanItems) MealCard(meal: meal),
          ],
        );
    }
  }

  Widget _buildNutrientIntake() {
    double sum(double Function(MealItem m) pick) =>
        mealPlanItems.fold<double>(0, (total, m) => total + pick(m));

    final stats = <_NutrientStat>[
      _NutrientStat('Energy', _mealNum(sum((m) => m.energy)), 'kcal',
          Icons.local_fire_department_rounded),
      _NutrientStat('Protein', _mealNum(sum((m) => m.protein)), 'g',
          Icons.egg_alt_rounded),
      _NutrientStat('Calcium', _mealNum(sum((m) => m.calcium)), 'mg',
          Icons.water_drop_rounded),
      _NutrientStat('Iron', _mealNum(sum((m) => m.iron)), 'mg',
          Icons.bloodtype_rounded),
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
    final items = <String>{
      for (final meal in mealPlanItems) ...meal.shopping,
    }.toList();

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
      child: Text(
        meal.emoji,
        style: const TextStyle(fontSize: 44),
      ),
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
          const Text('•  ',
              style: TextStyle(color: mealText, fontSize: 13, height: 1.3)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: mealText, fontSize: 13, height: 1.3),
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
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' ${stat.unit}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
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

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: blush,
                child: Icon(icon, size: 38, color: rose),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Recipe {
  final String name;
  final String category;
  final String description;
  final String time;
  final String difficulty;
  final String emoji;
  final Color color;
  final List<String> ingredients;
  final List<String> steps;

  const Recipe({
    required this.name,
    required this.category,
    required this.description,
    required this.time,
    required this.difficulty,
    required this.emoji,
    required this.color,
    required this.ingredients,
    required this.steps,
  });
}

const List<Recipe> sampleRecipes = [
  Recipe(
    name: 'Berry Yogurt Bowl',
    category: 'Breakfast',
    description: 'Creamy yogurt with berries and a little crunch.',
    time: '10 min',
    difficulty: 'Easy',
    emoji: '🫐',
    color: Color(0xFFE8E5FA),
    ingredients: [
      '1 cup plain yogurt',
      '1/2 cup mixed berries',
      '2 tablespoons granola',
      '1 teaspoon honey (optional)',
    ],
    steps: [
      'Spoon the yogurt into a bowl.',
      'Wash and add the mixed berries.',
      'Sprinkle granola over the top.',
      'Drizzle with honey if you like, then enjoy.',
    ],
  ),
  Recipe(
    name: 'Avocado Toast',
    category: 'Breakfast',
    description: 'A simple, satisfying toast with creamy avocado.',
    time: '10 min',
    difficulty: 'Easy',
    emoji: '🥑',
    color: Color(0xFFE2F0D9),
    ingredients: [
      '2 slices wholegrain bread',
      '1 ripe avocado',
      'A squeeze of lemon',
      'Salt and pepper to taste',
    ],
    steps: [
      'Toast the bread until golden.',
      'Mash the avocado with lemon juice.',
      'Spread avocado over the toast.',
      'Season with salt and pepper.',
    ],
  ),
  Recipe(
    name: 'Rainbow Rice Bowl',
    category: 'Lunch',
    description: 'Colourful veggies served with warm rice.',
    time: '20 min',
    difficulty: 'Easy',
    emoji: '🥗',
    color: Color(0xFFFFE9CF),
    ingredients: [
      '1 cup cooked rice',
      '1/2 cup sliced cucumber',
      '1/2 cup shredded carrot',
      '1/2 cup cooked protein of choice',
      'Your favourite dressing',
    ],
    steps: [
      'Place the warm rice in a bowl.',
      'Arrange the vegetables and protein on top.',
      'Add your favourite dressing.',
      'Mix together before eating.',
    ],
  ),
  Recipe(
    name: 'Creamy Tomato Pasta',
    category: 'Dinner',
    description: 'Comforting pasta with a gentle tomato sauce.',
    time: '25 min',
    difficulty: 'Medium',
    emoji: '🍝',
    color: Color(0xFFF8DDE0),
    ingredients: [
      '150 g pasta',
      '1 cup chopped tomatoes',
      '1 small garlic clove, minced',
      '2 tablespoons cooking cream',
      'Salt, pepper and herbs',
    ],
    steps: [
      'Cook pasta according to the packet instructions.',
      'Gently cook garlic and tomatoes in a pan.',
      'Stir in the cream and season to taste.',
      'Add the drained pasta and toss to coat.',
    ],
  ),
  Recipe(
    name: 'Banana Oat Bites',
    category: 'Snacks',
    description: 'Little banana and oat bites for snack time.',
    time: '18 min',
    difficulty: 'Easy',
    emoji: '🍌',
    color: Color(0xFFFFF0C9),
    ingredients: [
      '1 ripe banana',
      '3/4 cup rolled oats',
      'A pinch of cinnamon',
      '1 tablespoon chocolate chips (optional)',
    ],
    steps: [
      'Preheat the oven to 180°C.',
      'Mash the banana in a bowl.',
      'Mix in oats, cinnamon and optional chocolate chips.',
      'Shape into small bites and bake for 12–15 minutes.',
    ],
  ),
];

const List<String> categories = [
  'All',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snacks',
];

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  String selectedCategory = 'All';
  String searchText = '';
  final Set<String> favourites = {};

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = sampleRecipes.where((recipe) {
      final matchesCategory = selectedCategory == 'All' ||
          recipe.category == selectedCategory;
      final query = searchText.toLowerCase().trim();
      final matchesSearch = recipe.name.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query) ||
          recipe.ingredients.any((item) => item.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GROWWELL  ✿',
                              style: TextStyle(
                                color: rose,
                                fontSize: 11,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Recipes',
                              style: TextStyle(
                                color: ink,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                       CircleAvatar(
                        radius: 25,
                        backgroundColor: blush,
                        child:  Icon(Icons.restaurant_menu_rounded,
                            color: rose, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Little ideas for delicious, feel-good meals.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (value) => setState(() => searchText = value),
                    decoration: InputDecoration(
                      hintText: 'Search recipes or ingredients...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Find your craving',
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: rose,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : ink,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                          onSelected: (_) {
                            setState(() => selectedCategory = category);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Made with love',
                          style: TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${filteredRecipes.length} recipes',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (filteredRecipes.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'No recipes found. Try another search 💗',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = filteredRecipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      isFavourite: favourites.contains(recipe.name),
                      onFavouriteTap: () {
                        setState(() {
                          if (!favourites.add(recipe.name)) {
                            favourites.remove(recipe.name);
                          }
                        });
                      },
                    );
                  },
                  childCount: filteredRecipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavourite;
  final VoidCallback onFavouriteTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavourite,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailPage(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 145,
                  width: double.infinity,
                  color: recipe.color,
                  alignment: Alignment.center,
                  child: Text(recipe.emoji, style: const TextStyle(fontSize: 68)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: isFavourite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      onPressed: onFavouriteTap,
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? rose : ink,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      recipe.category,
                      style: const TextStyle(
                        color: rose,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: rose),
                      const SizedBox(width: 5),
                      Text(recipe.time,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department_outlined,
                          size: 16, color: rose),
                      const SizedBox(width: 5),
                      Text(recipe.difficulty,
                          style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      const Text(
                        'View recipe  →',
                        style: TextStyle(
                          color: rose,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text('Recipe details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: recipe.color,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(recipe.emoji, style: const TextStyle(fontSize: 90)),
          ),
          const SizedBox(height: 18),
          Text(
            recipe.name,
            style: const TextStyle(
              color: ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(recipe.description,
              style: const TextStyle(color: Colors.black54, fontSize: 15)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              _InfoPill(icon: Icons.schedule_rounded, text: recipe.time),
              _InfoPill(
                  icon: Icons.signal_cellular_alt_rounded,
                  text: recipe.difficulty),
              _InfoPill(icon: Icons.sell_outlined, text: recipe.category),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'Ingredients',
            style: TextStyle(
                color: ink, fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...recipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: rose, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ingredient)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Let’s make it',
            style: TextStyle(
                color: ink, fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(recipe.steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: blush,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: rose, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(recipe.steps[index]),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Enjoy your meal! ♡',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: rose, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: rose),
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}