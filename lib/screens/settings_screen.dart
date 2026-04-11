import 'package:flutter/material.dart';
import '../constants/app_l10n.dart';
import '../constants/locale_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
  }

  Future<void> _switchLanguage(String lang) async {
    await setLocale(lang);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.settingsTitle),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF8B0000).withValues(alpha: 0.3),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            _buildSectionTitle(AppL10n.soundSection),
            const SizedBox(height: 12),
            _buildToggleTile(
              icon: Icons.music_note,
              title: AppL10n.music,
              subtitle: _musicEnabled ? AppL10n.on : AppL10n.off,
              value: _musicEnabled,
              onChanged: (val) {
                setState(() => _musicEnabled = val);
                _saveSetting('musicEnabled', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleTile(
              icon: Icons.volume_up,
              title: AppL10n.soundEffects,
              subtitle: _soundEnabled ? AppL10n.on : AppL10n.off,
              value: _soundEnabled,
              onChanged: (val) {
                setState(() => _soundEnabled = val);
                _saveSetting('soundEnabled', val);
              },
            ),
            const SizedBox(height: 28),
            _buildSectionTitle(AppL10n.languageSection),
            const SizedBox(height: 12),
            _buildLanguageTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFDC143C), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFDC143C),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile() {
    final currentLang = localeNotifier.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: Color(0xFFDC143C), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppL10n.languageLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          // TR butonu
          _buildLangButton('TR', currentLang == 'tr'),
          const SizedBox(width: 8),
          // EN butonu
          _buildLangButton('EN', currentLang == 'en'),
        ],
      ),
    );
  }

  Widget _buildLangButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _switchLanguage(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDC143C)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC143C) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
