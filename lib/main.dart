import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:vampir_koylu/screens/welcome_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'services/auth_service.dart';

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
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF8B0000),
          secondary: const Color(0xFFDC143C),
        ),
      ),
      home: const AuthChecker(),
      routes: {
        '/main-menu': (context) => const MainMenuScreen(),
      },
    );
  }
}

// AUTH CHECKER - Kullanıcı giriş yapmış mı kontrol et
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDC143C),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Kullanıcı giriş yapmış
          return const MainMenuScreen();
        }

        // Kullanıcı giriş yapmamış
        return const WelcomeScreen();
      },
    );
  }
}

// ANA MENÜ
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _displayName = 'Yükleniyor...';
  String? _nickname;
  String _avatarColor = '#DC143C';
  bool _isGuest = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _displayName = user['displayName'];
        _nickname = user['nickname'];
        _avatarColor = user['avatarColor'];
        _isGuest = user['isGuest'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateRoom() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final roomsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('gameState', isEqualTo: 'waiting')
        .get();

    for (var doc in roomsSnapshot.docs) {
      final players = doc.data()['players'] as Map<String, dynamic>;
      if (players.containsKey(user['userId'])) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text(
                'Zaten bir odanız var',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Yeni oda oluşturmak için önce "${doc.id}" odasından ayrılmanız veya odayı kapatmanız gerekir.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'TAMAM',
                    style: TextStyle(color: Color(0xFFDC143C)),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateRoomScreen(),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFDC143C),
          ),
        ),
      );
    }

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
          child: Column(
            children: [
              // LOGO VE BAŞLIK
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🧛',
                      style: TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'VAMPİR KÖYLÜ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC143C),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // BUTONLAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          MenuButton(
                            text: 'ODA OLUŞTUR',
                            icon: Icons.add_circle,
                            onPressed: _navigateToCreateRoom,
                          ),
                          const SizedBox(height: 15),
                          MenuButton(
                            text: 'ODAYA KATIL',
                            icon: Icons.meeting_room,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const JoinRoomScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          MenuButton(
                            text: 'İSTATİSTİKLER',
                            icon: Icons.bar_chart,
                            onPressed: () {
                              debugPrint('İstatistikler tıklandı');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PROFİL BÖLÜMÜ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                          _avatarColor.replaceFirst('#', '0xFF'),
                        )),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // İsim ve nickname
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isGuest && _nickname != null)
                            Text(
                              '@$_nickname',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          if (_isGuest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Misafir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Logout butonu
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MENÜ BUTONU WIDGET
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
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B0000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}