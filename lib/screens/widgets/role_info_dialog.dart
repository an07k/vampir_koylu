import 'package:flutter/material.dart';
import '../../constants/app_l10n.dart';

class RoleInfoDialog extends StatelessWidget {
  final String role;

  const RoleInfoDialog({super.key, required this.role});

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
    'manipulator': '🎭',
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
    'manipulator': Color(0xFF8A2BE2),
  };

  @override
  Widget build(BuildContext context) {
    final color = roleColors[role] ?? Colors.white;
    final icon = roleIcons[role] ?? '❓';
    final name = AppL10n.roleNames[role] ?? AppL10n.unknown;
    final description =
        AppL10n.roleDescriptions[role] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 25),
          Text(icon, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 15),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
                color: Colors.white70, fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                AppL10n.close,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
