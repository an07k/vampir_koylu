import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/role_distribution.dart';
import 'screens/login_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /**  testing role distribution
  RoleDistribution.testRoles();
  */
  
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Bağlantı kontrol ediliyor
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFDC143C),
                ),
              ),
            );
          }

          // Kullanıcı giriş yapmış mı?
          if (snapshot.hasData) {
            return const MainMenuScreen();
          }

          // Giriş yapmamış
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _username = 'Yükleniyor...';
  String _avatarColor = '#DC143C';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()!['username'];
          _avatarColor = userDoc.data()!['avatarColor'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı verisi yükleme hatası: $e');
      setState(() {
        _username = 'Misafir';
        _isLoading = false;
      });
    }
  }

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateRoomScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Odaya Katıl Butonu
                MenuButton(
                  text: 'ODAYA KATIL',
                  icon: Icons.meeting_room,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinRoomScreen(),
                      ),
                    );
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
                    debugPrint('👤 Profil tıklandı');
                  },
                  icon: Icon(
                    Icons.person,
                    color: Color(int.parse(_avatarColor.replaceFirst('#', '0xFF'))),
                  ),
                  label: Text(
                    _username,
                    style: TextStyle(
                      color: Color(int.parse(_avatarColor.replaceFirst('#', '0xFF'))),
                      fontWeight: FontWeight.bold,
                    ),
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