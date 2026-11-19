import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'authentication.dart';
import 'setting.dart';
import 'nutrition.dart';
import 'recipe.dart';
import 'growth.dart';
import 'home.dart';

// Shared neutral colours
const Color appBackground = Color(0xFFFAFAFC);
const Color cardWhite = Color(0xFFFFFFFF);
const Color ink = Color(0xFF24252B);
const Color secondaryText = Color(0xFF70717A);
const Color borderGrey = Color(0xFFE5E5EA);

// Home — Blue
const Color homeBlue = Color(0xFF2878D0);
const Color homeBlueLight = Color(0xFFEAF3FF);
const Color homeBlueDark = Color(0xFF17549B);

// Growth — Green
const Color growthGreen = Color(0xFF32966A);
const Color growthGreenLight = Color(0xFFE5F5EB);
const Color growthGreenDark = Color(0xFF216747);

// Nutrition — Yellow
const Color nutritionYellow = Color(0xFFF2C230);
const Color nutritionYellowLight = Color(0xFFFFF7D6);
const Color nutritionYellowDark = Color(0xFF946900);

// Recipes — Red
const Color recipesRed = Color(0xFFE34D4D);
const Color recipesRedLight = Color(0xFFFDEAEA);
const Color recipesRedDark = Color(0xFFB92F38);

// More — Neutral
const Color moreCharcoal = Color(0xFF45464F);
const Color moreGreyLight = Color(0xFFF0F0F3);
const Color moreCharcoalDark = Color(0xFF292A30);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SiCilik());
}

class SiCilik extends StatelessWidget {
  const SiCilik({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Si Cilik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2878D0),
          surface: const Color(0xFFFFFFFF),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

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
              child: CircularProgressIndicator(color: Color(0xFF2878D0)),
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

//NAVBAR
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  String? selectedChildId;

  String get ownerId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    GrowthReminders.cancelLegacy();
  }

  // Section colors
  static const Color homeBlue = Color(0xFF2878D0);
  static const Color growthGreen = Color(0xFF32966A);
  static const Color nutritionYellow = Color(0xFFF2C230);
  static const Color recipesRed = Color(0xFFE34D4D);
  static const Color moreCharcoal = Color(0xFF45464F);

  // Light indicator colors
  static const Color homeLight = Color(0xFFEAF3FF);
  static const Color growthLight = Color(0xFFE5F5EB);
  static const Color nutritionLight = Color(0xFFFFF7D6);
  static const Color recipesLight = Color(0xFFFDEAEA);
  static const Color moreLight = Color(0xFFF0F0F3);

  Color get selectedColor {
    switch (selectedIndex) {
      case 0:
        return homeBlue;
      case 1:
        return growthGreen;
      case 2:
        return nutritionYellow;
      case 3:
        return recipesRed;
      case 4:
        return moreCharcoal;
      default:
        return homeBlue;
    }
  }

  Color get selectedIndicatorColor {
    switch (selectedIndex) {
      case 0:
        return homeLight;
      case 1:
        return growthLight;
      case 2:
        return nutritionLight;
      case 3:
        return recipesLight;
      case 4:
        return moreLight;
      default:
        return homeLight;
    }
  }

  // Pages are rebuilt with the current navigation and child selection state.
  List<Widget> get pages => [
    HomeScreen(
      ownerId: ownerId,
      onNavigate: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    ),
    GrowthPage(
      ownerId: ownerId,
      initialChildId: selectedChildId,
      visible: selectedIndex == 1,
      onChildSelected: (id) {
        setState(() => selectedChildId = id);
      },
    ),
    MealPlanPage(),
    RecipesPage(),
    Setting(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Tetapan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      body: IndexedStack(index: selectedIndex, children: pages),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: selectedIndicatorColor,
          height: 72,
          elevation: 0,

          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: selectedColor, size: 24);
            }

            return const IconThemeData(color: Color(0xFF80868B), size: 23);
          }),

          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: selectedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }

            return const TextStyle(
              color: Color(0xFF80868B),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            );
          }),
        ),

        child: NavigationBar(
          selectedIndex: selectedIndex,

          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Utama',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_rounded),
              selectedIcon: Icon(Icons.trending_up_rounded),
              label: 'Progres',
            ),
            NavigationDestination(
              icon: Icon(Icons.spa_outlined),
              selectedIcon: Icon(Icons.spa_rounded),
              label: 'Nutrisi',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Resipi',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Tetapan',
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable placeholder page
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 65, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
