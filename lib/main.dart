import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VampirKoyluApp());
}

class VampirKoyluApp extends StatelessWidget {
  const VampirKoyluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vampir Köylü',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF8B0000), // Koyu kırmızı
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Koyu gri
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF8B0000),
          secondary: const Color(0xFFDC143C),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/main-menu': (context) => const MainMenuScreen(),
      },
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Başlık
                const Icon(
                  Icons.nights_stay,
                  size: 100,
                  color: Color(0xFFDC143C),
                ),
                const SizedBox(height: 20),
                const Text(
                  'VAMPİR KÖYLÜ',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Oda Oluştur Butonu
                MenuButton(
                  text: 'ODA OLUŞTUR',
                  icon: Icons.add_circle_outline,
                  onPressed: () {
                    // TODO: Oda oluşturma ekranına git
                    debugPrint('🏠 Oda Oluştur tıklandı');
                  },
                ),
                const SizedBox(height: 20),
                
                // Odaya Katıl Butonu
                MenuButton(
                  text: 'ODAYA KATIL',
                  icon: Icons.meeting_room,
                  onPressed: () {
                    // TODO: Odaya katılma ekranına git
                    debugPrint('🚪 Odaya Katıl tıklandı');
                  },
                ),
                const SizedBox(height: 20),
                
                // İstatistikler Butonu
                MenuButton(
                  text: 'İSTATİSTİKLER',
                  icon: Icons.bar_chart,
                  onPressed: () {
                    // TODO: İstatistikler ekranına git
                    debugPrint('📊 İstatistikler tıklandı ');
                  },
                ),
              
                const SizedBox(height: 20),

                // Firebase Test Butonu
                MenuButton(
                  text: 'TEST FİREBASE',
                  icon: Icons.cloud,
                  onPressed: () async {
                    try {
                      // Firestore'a test verisi yaz
                      await FirebaseFirestore.instance
                          .collection('test')
                          .add({
                        'message': 'Firebase çalışıyor!',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      
                      debugPrint('✅ Firebase BAŞARILI!');
                    } catch (e) {
                      debugPrint('❌ Firebase HATA: $e');
                    }
                  },
                ),
                const SizedBox(height: 40),
                
                // Profil Butonu (küçük, altta)
                TextButton.icon(
                  onPressed: () {
                    // TODO: Profil ekranına git
                    print('👤 Profil tıklandı');
                  },
                  icon: const Icon(Icons.person, color: Colors.white70),
                  label: const Text(
                    'Misafir',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Özel Buton Widget'ı
class MenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFDC143C)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC143C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}