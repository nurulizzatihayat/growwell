import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database.dart';

import 'package:url_launcher/url_launcher.dart';

class Setting extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const Setting({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _loggingOut = false;

  static const Color darkText = Color(0xFF24252B);
  static const Color secondaryText = Color(0xFF70717A);
  static const Color charcoal = Color(0xFF45464F);
  static const Color lightGrey = Color(0xFFF0F0F3);
  static const Color borderGrey = Color(0xFFE5E5EA);

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'User';

    final profile = await DatabaseHelper.getProfile(user.uid);

    if (profile == null) return 'User';

    return profile['name'] as String? ?? 'User';
  }

  Future<void> _openWebsite() async {
    final Uri url = Uri.parse('https://YOUR-WEBSITE.com');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open website');
    }
  }

  Future<void> _sendEnquiry() async {
    final Uri url = Uri.parse('https://YOUR-WEBSITE.com');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
              style: TextStyle(color: secondaryText, fontSize: 14),
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
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),

                        const SizedBox(height: 5),

                        FutureBuilder<String>(
                          future: getUserName(),
                          builder: (context, snapshot) {
                            final user = FirebaseAuth.instance.currentUser;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.data ?? 'Loading...',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'No email available',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          },
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
                label: Text(_loggingOut ? 'Sedang keluar...' : 'Log Keluar'),
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
                  style: TextStyle(color: secondaryText, fontSize: 12),
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

            Container(
              decoration: BoxDecoration(
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
                      style: TextStyle(color: secondaryText, fontSize: 12),
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
                      style: TextStyle(color: secondaryText, fontSize: 12),
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
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
