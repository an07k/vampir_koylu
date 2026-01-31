import 'package:flutter/material.dart';

class RoleInfoDialog extends StatelessWidget {
  final String role;

  const RoleInfoDialog({
    super.key,
    required this.role,
  });

  // ROL AÇIKLAMALARI
  static const Map<String, String> roleDescriptions = {
    'vampir':
        'Gece diğer vampirlerle birlikte bir köylüyü öldürüyorsun. Gündüz oymada köylülere karış ve tespite çakılma!',
    'koylu':
        'Gündüz oylama ile vampirleri bul ve öldür. Sana özel bir yetki yok ama gözlemle her şeyi çözebilirsin!',
    'doktor':
        'Gece bir kişiyi koruyabilirsin. Eğer vampirler o kişiyi seçerse ölmez! Ama aynı kişiyi iki gece üst üste koruyamazsın.',
    'asik':
        'Oyun başında bir kişi seç, o senin aşkın. Eğer aşkın masum öldürülürse ertesi gün 1 kişi öldürme hakkın olur. Ama aşkın vampireyse öldürüldüğünde kendin ölürsün!',
    'deli':
        'Eğer kendini oylama ile astırırsan kazanırsın! Aksi takdirde her zaman kaybedersin. Herkes seni şüphelendirmeye çalış!',
    'dedektif':
        'Bir gece seçtiğin kişinin rolünü tam olarak öğrenebilirsin. Bu bilgiyi iyi kullan!',
    'misafir':
        'Gece gittiğin kişiyi işinden alıkoyarsın. Doktorsa koruma yapamaz, vampireyse öldürme yapamaz!',
    'polis':
        'Bir gece nöbet tutarsan, o eve kim geldiğini öğrenirsin. Kim vampir kim değil bulmana yardımcı olabilir!',
    'takipci':
        'Bir eve sızırsan, o kişi bir yere giderse nereye gittiğini öğrenirsin. Vampirlerin hareketlerini izle!',
  };

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
  Widget build(BuildContext context) {
    final color = roleColors[role] ?? Colors.white;
    final icon = roleIcons[role] ?? '❓';
    final name = roleNames[role] ?? 'BILINMIYOR';
    final description = roleDescriptions[role] ?? 'Açıklama bulunamadı.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 25),

          // Icon
          Text(
            icon,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 15),

          // Rol Adı
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

          // Divider
          Container(
            height: 1,
            color: color.withOpacity(0.3),
          ),
          const SizedBox(height: 20),

          // Açıklama
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Kapatl Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'KAPAT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}