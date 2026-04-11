import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_l10n.dart';
import 'create_account_screen.dart';
import 'login_account_screen.dart';
import 'guest_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF8B0000).withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
                  const Text(
                    '🧛',
                    style: TextStyle(fontSize: 100),
                  ),
                  const SizedBox(height: 20),

                  // BAŞLIK
                  const Text(
                    ' MODERATE IT! ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC143C),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // HESAP OLUŞTUR
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateAccountScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        AppL10n.createAccount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC143C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // GİRİŞ YAP
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginAccountScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: Text(
                        AppL10n.loginBtn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // MİSAFİR OYNA
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GuestLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, color: Colors.white70),
                      label: Text(
                        AppL10n.playAsGuest,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // GİZLİLİK POLİTİKASI & KULLANIM KOŞULLARI
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        AppL10n.privacyNoteBefore,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://an07k.github.io/moderateit-privacy/');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          AppL10n.privacyPolicyLink,
                          style: const TextStyle(
                            color: Color(0xFFDC143C),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        AppL10n.privacyNoteAnd,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://an07k.github.io/moderateit-privacy/terms');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          AppL10n.termsOfUseLink,
                          style: const TextStyle(
                            color: Color(0xFFDC143C),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        AppL10n.privacyNoteAfter,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
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
