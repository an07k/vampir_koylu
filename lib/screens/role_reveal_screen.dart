import 'package:flutter/material.dart';

class RoleRevealScreen extends StatefulWidget {
  final String role;

  const RoleRevealScreen({
    super.key,
    required this.role,
  });

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _controller;

  // ROL İCON VE RENK
  static const Map<String, String> roleIcons = {
    'vampir': '🧛',
    'koylu': '👨‍🌾',
    'doktor': '🏥',
    'asik': '💘',
    'deli': '🤪',
    'dedektif': '🔍',
    'misafir': '🏠',
    'polis': '👮',
    'takipci': '👣',
  };

  static const Map<String, String> roleNames = {
    'vampir': 'VAMPİR',
    'koylu': 'KÖYLÜ',
    'doktor': 'DOKTOR',
    'asik': 'ÂŞIK',
    'deli': 'DELİ',
    'dedektif': 'DETEKTİF',
    'misafir': 'MİSAFİR',
    'polis': 'POLİS',
    'takipci': 'TAKİPÇİ',
  };

  static const Map<String, Color> roleColors = {
    'vampir': Color(0xFFDC143C),
    'koylu': Color(0xFF32CD32),
    'doktor': Color(0xFF1E90FF),
    'asik': Color(0xFFFF69B4),
    'deli': Color(0xFFFF8C00),
    'dedektif': Color(0xFFFFD700),
    'misafir': Color(0xFF9370DB),
    'polis': Color(0xFF00CED1),
    'takipci': Color(0xFFCD853F),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _revealRole() {
    setState(() {
      _revealed = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final color = roleColors[widget.role] ?? Colors.white;
    final icon = roleIcons[widget.role] ?? '❓';
    final name = roleNames[widget.role] ?? 'BILINMIYOR';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              color.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KAPAL / AÇIK KART
                GestureDetector(
                  onTap: _revealed ? null : _revealRole,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _revealed
                        ? _revealedCard(color, icon, name)
                        : _hiddenCard(),
                  ),
                ),
                const SizedBox(height: 40),

                // DEVAM BUTONU (sadece reveal sonrası)
                if (_revealed)
                  AnimatedOpacity(
                    opacity: _revealed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'DEVAM',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  // KAPAL KART
  Widget _hiddenCard() {
    return Container(
      key: const ValueKey('hidden'),
      width: 250,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎴',
              style: TextStyle(fontSize: 80),
            ),
            SizedBox(height: 20),
            Text(
              'TAP TO REVEAL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AÇIK KART
  Widget _revealedCard(Color color, String icon, String name) {
    return Container(
      key: const ValueKey('revealed'),
      width: 250,
      height: 350,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}