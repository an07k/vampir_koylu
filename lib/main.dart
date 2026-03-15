import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'themes/app_theme.dart';
import 'package:vampir_koylu/screens/welcome_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'services/auth_service.dart';
import 'services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Baglanti hatasi: $e',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }
  runApp(const VampirKoyluApp());
}

class VampirKoyluApp extends StatelessWidget {
  const VampirKoyluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.darkTheme,
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
                color: AppColors.secondary,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainMenuScreen();
        }

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
  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = UserDataService.loadUserData();
  }

  Future<void> _navigateToCreateRoom() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final activeRoomId = await UserDataService.getUserActiveRoom(user['userId']);

    if (activeRoomId != null && mounted) {
      _showAlreadyInRoomDialog(activeRoomId);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
      );
    }
  }

  void _showAlreadyInRoomDialog(String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          AppStrings.alreadyInRoom,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppStrings.leaveRoomMessage.replaceFirst('{roomId}', roomId),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              AppStrings.ok,
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }

        final userData = snapshot.data!;
        final displayName = userData['displayName'] ?? AppStrings.loading;
        final nickname = userData['nickname'];
        final avatarColor = userData['avatarColor'] ?? '#DC143C';
        final isGuest = userData['isGuest'] ?? false;
        final gold = userData['gold'] ?? 0;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.primary.withOpacity(0.3),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildMenuButtons(),
                  _buildProfileSection(
                    displayName,
                    nickname,
                    avatarColor,
                    isGuest,
                    gold,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('🧛', style: TextStyle(fontSize: 80)),
          SizedBox(height: 20),
          Text(
            AppStrings.appTitle,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          MenuButton(
            text: AppStrings.createRoom,
            icon: Icons.add_circle,
            onPressed: _navigateToCreateRoom,
          ),
          const SizedBox(height: 15),
          MenuButton(
            text: AppStrings.joinRoom,
            icon: Icons.meeting_room,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
              );
            },
          ),
          const SizedBox(height: 15),
          MenuButton(
            text: AppStrings.statistics,
            icon: Icons.bar_chart,
            onPressed: () {
              debugPrint('Statistics button pressed - not yet implemented');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    String displayName,
    String? nickname,
    String avatarColor,
    bool isGuest,
    int gold,
  ) {
    return Container(
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
          _buildAvatar(displayName, avatarColor),
          const SizedBox(width: 15),
          _buildUserInfo(displayName, nickname, isGuest),
          if (!isGuest) _buildGoldBadge(gold),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar(String displayName, String avatarColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Color(int.parse(avatarColor.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String displayName, String? nickname, bool isGuest) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (!isGuest && nickname != null)
            Text(
              '@$nickname',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          if (isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: const Text(
                AppStrings.guest,
                style: TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoldBadge(int gold) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent, width: 1),
        ),
        child: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '$gold',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: AppColors.textSecondary),
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