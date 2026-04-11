import 'package:flutter/material.dart';
import '../constants/app_l10n.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['isGuest'] == true) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user['userId'])
        .get();

    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.statisticsTitle),
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFDC143C)))
            : _userData == null
                ? Center(
                    child: Text(
                      AppL10n.guestNoStats,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildStats(),
      ),
    );
  }

  Widget _buildStats() {
    final totalGames = (_userData!['totalGames'] ?? 0) as int;
    final wins = (_userData!['wins'] ?? 0) as int;
    final losses = (_userData!['losses'] ?? 0) as int;
    final winRate = totalGames > 0 ? (wins / totalGames * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🧛', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 8),
          Text(
            _userData!['displayName'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildWinRateCircle(winRate),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      '🎮', AppL10n.totalGames, '$totalGames', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      '🏆', AppL10n.won, '$wins', Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      '💀', AppL10n.lost, '$losses', Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateCircle(double winRate) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDC143C), width: 4),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${winRate.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Color(0xFFDC143C),
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
          Text(
            AppL10n.winrate,
            style: const TextStyle(
                color: Colors.white54, fontSize: 14, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
