import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'database.dart';
import 'growth_page.dart';
import 'home_preview.dart';

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
          return MainNavigation(ownerId: snapshot.data!.uid);
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
      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: rose, width: 1.5),
    ),
  );
}


class MainNavigation extends StatefulWidget {
  final String ownerId;
  const MainNavigation({super.key, required this.ownerId});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  int? selectedChildId;

  List<Widget> get pages => [
    HomePage(ownerId: widget.ownerId, visible: selectedIndex == 0, selectedChildId: selectedChildId,
      onChildSelected: (id) => setState(() => selectedChildId = id),
      onNavigate: (index) => setState(() => selectedIndex = index)),
    GrowthPage(ownerId: widget.ownerId, initialChildId: selectedChildId,
      visible: selectedIndex == 1,
      onChildSelected: (id) => setState(() => selectedChildId = id)),
    const PlaceholderPage(
      title: 'Nutrition',
      subtitle: 'Your nutrition information will go here.',
      icon: Icons.spa_rounded,
    ),
    const RecipesPage(),
    const MorePage(),
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
        indicatorColor: blush,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.trending_up_rounded),
            label: 'Growth',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate returns the user to the login screen.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'More',
            style: TextStyle(
              color: ink,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontSize: 18, color: ink)),
          const SizedBox(height: 8),
          Text(
            FirebaseAuth.instance.currentUser?.email ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loggingOut ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(_loggingOut ? 'Logging out...' : 'Log out'),
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                        child: Icon(Icons.restaurant_menu_rounded,
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
                    color: Colors.white.withOpacity(0.94),
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
