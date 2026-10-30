import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'growth_page.dart';
import 'home_preview.dart';
import 'recipe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GrowWell());
}

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

// Growth — Yellow
const Color growthYellow = Color(0xFFF2C230);
const Color growthYellowLight = Color(0xFFFFF7D6);
const Color growthYellowDark = Color(0xFF946900);

// Nutrition — Green
const Color nutritionGreen = Color(0xFF32966A);
const Color nutritionGreenLight = Color(0xFFE5F5EB);
const Color nutritionGreenDark = Color(0xFF216747);

// Recipes — Red
const Color recipesRed = Color(0xFFE34D4D);
const Color recipesRedLight = Color(0xFFFDEAEA);
const Color recipesRedDark = Color(0xFFB92F38);

// More — Neutral
const Color moreCharcoal = Color(0xFF45464F);
const Color moreGreyLight = Color(0xFFF0F0F3);
const Color moreCharcoalDark = Color(0xFF292A30);

class GrowWell extends StatelessWidget {
  const GrowWell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowWell',
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
              child: CircularProgressIndicator(
                color: Color(0xFF2878D0),
              ), 
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

//LOGIN
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

      // AuthGate will automatically show MainNavigation.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Emel atau kata laluan salah. Sila cuba lagi.';
          break;
        case 'invalid-email':
          message = 'Sila masukkan alamat emel yang sah.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percubaan. Sila cuba lagi kemudian.';
          break;
        default:
          message = e.message ?? 'Log masuk gagal. Sila cuba lagi.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila semak sambungan internet anda dan cuba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A73E8);
    const darkText = Color(0xFF202124);
    const secondaryText = Color(0xFF5F6368);
    const borderColor = Color(0xFFDADCE0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Simple app icon
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          size: 30,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Anak Sihat, Ibu Ceria',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Selamat kembali. Log masuk untuk teruskan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 36),

                    const Text(
                      'Emel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'Sila masukkan emel anda',
                        hintStyle: const TextStyle(color: secondaryText),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Sila masukkan emel anda.';
                        }

                        if (!value.contains('@') ||
                            !value.contains('.')) {
                          return 'Sila masukkan alamat emel yang sah.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Kata laluan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata laluan anda',
                        hintStyle: const TextStyle(color: secondaryText),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: secondaryText,
                          ),
                          tooltip: _hidePassword
                              ? 'Show password'
                              : 'Hide password',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sila masukkan kata laluan anda.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Log masuk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Tiada akaun? ",
                          style: TextStyle(
                            color: Color(0xFF85858D),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar akaun',
                            style: TextStyle(
                              color: Color(0xFF2878D0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Pastikan tumbesaran anak anda sihat dan ibu bapa gembira.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//REGISTER

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
  bool _hideConfirmPassword = true;
  bool _agreeToTerms = false;

  static const Color blue = Color(0xFF1A73E8);
  static const Color darkText = Color(0xFF202124);
  static const Color secondaryText = Color(0xFF5F6368);
  static const Color borderColor = Color(0xFFDADCE0);

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
          content: Text('Sila bersetuju untuk meneruskan.'),
        ),
      );
      return;
    }

    try {
      // Create a Firebase account.
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Akaun tidak dapat dibuat. Sila cuba lagi.');
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
          content: Text('Akaun berjaya dibuat!'),
        ),
      );

      // Sign out so the user can log in normally.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Emel ini sudah mempunyai akaun.';
          break;
        case 'invalid-email':
          message = 'Sila masukkan alamat emel yang sah.';
          break;
        case 'weak-password':
          message = 'Sila pilih kata laluan yang lebih kuat.';
          break;
        default:
          message = e.message ?? 'Pendaftaran gagal. Sila cuba lagi.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akaun anda mungkin telah dibuat, tetapi gagal menyimpan profil anda. Sila periksa sambungan anda dan cuba lagi.',
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF80868B),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: secondaryText,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: blue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create account',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  // App icon
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        color: blue,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Ikuti perkembangan anak anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Daftar akaun untuk mula menggunakan aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name
                  _fieldLabel('Nama anda'),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'Apa nama anda?',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Sila masukkan nama anda.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email
                  _fieldLabel('Emel'),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'anda@gmail.com',
                      icon: Icons.mail_outline,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty ||
                          !email.contains('@') ||
                          !email.contains('.')) {
                        return 'Sila masukkan alamat emel yang sah.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password
                  _fieldLabel('Kata laluan'),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'Sekurang-kurangnya 6 aksara',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Sila gunakan sekurang-kurangnya 6 aksara.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm password
                  _fieldLabel('Sahkan kata laluan'),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: _hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    decoration: _inputDecoration(
                      hint: 'Taip semula kata laluan anda',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hideConfirmPassword =
                                !_hideConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _hideConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Kata laluan tidak sepadan.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Terms and conditions
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: blue,
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    title: const Text(
                      'Saya bersetuju dengan syarat dan dasar privasi aplikasi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Register button
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Buat akaun',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Sudah mempunyai akaun? Log masuk',
                      style: TextStyle(
                        color: blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Mula mengurus tumbesaran anak anda hari ini!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
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

//NAVBAR

class MainNavigation extends StatefulWidget {
  final String ownerId;

  const MainNavigation({
    super.key,
    required this.ownerId,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  int? selectedChildId;

  // Section colors
  static const Color homeBlue = Color(0xFF2878D0);
  static const Color growthYellow = Color(0xFFF2C230);
  static const Color nutritionGreen = Color(0xFF32966A);
  static const Color recipesRed = Color(0xFFE34D4D);
  static const Color moreCharcoal = Color(0xFF45464F);

  // Light indicator colors
  static const Color homeLight = Color(0xFFEAF3FF);
  static const Color growthLight = Color(0xFFFFF7D6);
  static const Color nutritionLight = Color(0xFFE5F5EB);
  static const Color recipesLight = Color(0xFFFDEAEA);
  static const Color moreLight = Color(0xFFF0F0F3);

  Color get selectedColor {
    switch (selectedIndex) {
      case 0:
        return homeBlue;
      case 1:
        return growthYellow;
      case 2:
        return nutritionGreen;
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

  List<Widget> get pages => [
        HomePage(
          ownerId: widget.ownerId,
          visible: selectedIndex == 0,
          selectedChildId: selectedChildId,
          onChildSelected: (id) {
            setState(() => selectedChildId = id);
          },
          onNavigate: (index) {
            setState(() => selectedIndex = index);
          },
        ),

        GrowthPage(
          ownerId: widget.ownerId,
          initialChildId: selectedChildId,
          visible: selectedIndex == 1,
          onChildSelected: (id) {
            setState(() => selectedChildId = id);
          },
        ),

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
      backgroundColor: const Color(0xFFF8FAFD),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: selectedIndicatorColor,
          height: 72,
          elevation: 0,

          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(
                  color: selectedColor,
                  size: 24,
                );
              }

              return const IconThemeData(
                color: Color(0xFF80868B),
                size: 23,
              );
            },
          ),

          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (states) {
              if (states.contains(MaterialState.selected)) {
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
            },
          ),
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
              label: 'Pertumbuhan',
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
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Tetapan',
            ),
          ],
        ),
      ),
    );
  }
}

//MORE (SETTINGS)

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();

}



class _MorePageState extends State<MorePage> {
  bool _loggingOut = false;

  static const Color darkText = Color(0xFF24252B);
  static const Color secondaryText = Color(0xFF70717A);
  static const Color charcoal = Color(0xFF45464F);
  static const Color lightGrey = Color(0xFFF0F0F3);
  static const Color borderGrey = Color(0xFFE5E5EA);

  Future<void> _openWebsite() async {
  final Uri url = Uri.parse('https://YOUR-WEBSITE.com');

  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    debugPrint('Could not open website');
  }
}

Future<void> _sendEnquiry() async {
  final Uri url = Uri.parse('https://YOUR-WEBSITE.com');

  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    debugPrint('Could not open website');
  }
}

  Future<void> _logout() async {
    setState(() => _loggingOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate returns the user to the login screen.
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat log keluar. Sila cuba lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Page heading
            const Text(
              'Tetapan',
              style: TextStyle(
                color: darkText,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Urus akaun dan tetapan anda.',
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // Account section
            const Text(
              'AKAUN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF85858D),
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            // Account information card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderGrey),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: charcoal,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log masuk sebagai',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          email,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _loggingOut ? null : _logout,
                icon: _loggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  _loggingOut ? 'Sedang keluar...' : 'Log Keluar',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: charcoal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: charcoal.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Settings section
            const Text(
              'KEUTAMAAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF85858D),
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderGrey),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: secondaryText,
                ),
                title: const Text(
                  'Tentang',
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Memastikan tumbesaran anak anda sihat dan ibu bapa gembira.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: secondaryText,
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'GrowWell',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'Mula mengurus tumbesaran anak anda hari ini!',
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'CONTACT US',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF85858D),
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Container(decoration: BoxDecoration(
                border: Border.all(color: borderGrey),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF45464F),
                    ),
                    title: const Text(
                      'Laman Web Rasmi',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Semak maklumat lanjut di laman web rasmi kami.',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _openWebsite,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF45464F),
                    ),
                    title: const Text(
                      'Hantaran Pertanyaan',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Hubungi orang yang bertanggungjawab untuk bertanya soalan',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _sendEnquiry,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Center(
              child: Text(
                'Mula mengurus tumbesaran anak anda hari ini!',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
                backgroundColor: const Color(0xFFE5F5EB),
                child: Icon(
                  icon,
                  size: 38,
                  color: const Color(0xFF32966A),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24252B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}