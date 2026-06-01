import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/room_service.dart';
import 'tabu_cards.dart';

enum _Stage { loading, ready, playing, roundSummary, finished }

/// Single-device Tabu. Teams take turns on the same phone: the describer
/// explains the word without saying any forbidden word; teammates guess.
/// Each team has a limited number of passes for the whole game. All state is
/// local — only the lobby/match transition touches Firestore.
class TabuMatchScreen extends StatefulWidget {
  final String roomCode;
  final String matchId;
  final String seatId;

  const TabuMatchScreen({
    super.key,
    required this.roomCode,
    required this.matchId,
    required this.seatId,
  });

  @override
  State<TabuMatchScreen> createState() => _TabuMatchScreenState();
}

class _TabuMatchScreenState extends State<TabuMatchScreen> {
  static const _teal = Color(0xFF00897B);

  _Stage _stage = _Stage.loading;
  int _targetScore = 30;
  int _roundDuration = 60;
  int _passLimit = 3;

  List<String> _teamNames = const ['Takım 1', 'Takım 2'];
  late List<int> _scores;
  int _passesLeft = 0; // refilled to _passLimit at the start of each round
  int _currentTeam = 0;
  int? _winner;

  late List<TabuCard> _deck;
  int _deckIndex = 0;

  int _remaining = 0;
  int _roundDelta = 0;
  int _roundCorrect = 0;
  int _roundTaboo = 0;
  int _roundPassUsed = 0;
  Timer? _timer;

  int get _teamCount => _teamNames.length;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('matches')
        .doc(widget.matchId)
        .get();
    final cfg = (doc.data()?['config'] as Map?)?.cast<String, dynamic>() ?? {};
    if (!mounted) return;
    setState(() {
      _targetScore = cfg['targetScore'] ?? 30;
      _roundDuration = cfg['roundDuration'] ?? 60;
      _passLimit = cfg['passLimit'] ?? 3;
      final teams = (cfg['teams'] as List?)?.cast<String>();
      if (teams != null && teams.length >= 2) _teamNames = teams;
      final categories =
          (cfg['categories'] as List?)?.cast<String>() ?? const ['genel'];
      _deck = buildDeck(categories)..shuffle();
      _scores = List<int>.filled(_teamCount, 0);
      _stage = _Stage.ready;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TabuCard get _card => _deck[_deckIndex % _deck.length];

  void _nextCard() {
    _deckIndex++;
    if (_deckIndex % _deck.length == 0) _deck.shuffle();
  }

  void _startRound() {
    setState(() {
      _stage = _Stage.playing;
      _remaining = _roundDuration;
      _roundDelta = 0;
      _roundCorrect = 0;
      _roundTaboo = 0;
      _roundPassUsed = 0;
      _passesLeft = _passLimit; // passes refill every round
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        _endRound();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _correct() {
    setState(() {
      _roundDelta++;
      _roundCorrect++;
      _nextCard();
    });
  }

  void _taboo() {
    setState(() {
      _roundDelta--;
      _roundTaboo++;
      _nextCard();
    });
  }

  void _pass() {
    if (_passesLeft <= 0) return;
    setState(() {
      _passesLeft--;
      _roundPassUsed++;
      _nextCard();
    });
  }

  void _endRound() {
    _timer?.cancel();
    final newScore = (_scores[_currentTeam] + _roundDelta).clamp(0, 1 << 30);
    setState(() {
      _scores[_currentTeam] = newScore;
      if (newScore >= _targetScore) _winner = _currentTeam;
      _stage = _Stage.roundSummary;
    });
  }

  void _continueFromSummary() {
    setState(() {
      if (_winner != null) {
        _stage = _Stage.finished;
      } else {
        _stage = _Stage.ready;
        _currentTeam = (_currentTeam + 1) % _teamCount;
      }
    });
  }

  Future<void> _exit() async {
    await RoomService.closeRoom(widget.roomCode);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main-menu', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101814),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.loading =>
            const Center(child: CircularProgressIndicator(color: _teal)),
          _Stage.ready => _readyView(),
          _Stage.playing => _playingView(),
          _Stage.roundSummary => _roundSummaryView(),
          _Stage.finished => _finishedView(),
        },
      ),
    );
  }

  Widget _scoreboard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(_teamCount, (i) {
          final active = i == _currentTeam;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: active
                    ? _teal.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: active ? _teal : Colors.white12,
                    width: active ? 2 : 1),
              ),
              child: Column(
                children: [
                  Text(_teamNames[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${_scores[i]}',
                      style: TextStyle(
                          color: active ? _teal : Colors.white38,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _readyView() {
    return Column(
      children: [
        _scoreboard(),
        Text('Hedef: $_targetScore puan',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        const Text('🗣️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text('Sıra: ${_teamNames[_currentTeam]}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Anlatıcı telefonu alsın, hazır olunca başlat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _startRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('BAŞLAT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
        ),
        TextButton(
          onPressed: _confirmExit,
          child:
              const Text('Oyundan çık', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _playingView() {
    final card = _card;
    final low = _remaining <= 10;
    final passLeft = _passesLeft;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_teamNames[_currentTeam],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (low ? Colors.red : _teal).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_remaining sn',
                    style: TextStyle(
                        color: low ? Colors.red : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              Text('Puan: $_roundDelta',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: _teal.withValues(alpha: 0.5), width: 2),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(card.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                      height: 2,
                      width: 120,
                      color: _teal.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: card.forbidden
                          .map((w) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(w,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Color(0xFFE57373),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              _actionBtn('❌\nTabu', Colors.red, _taboo),
              const SizedBox(width: 10),
              _actionBtn(
                passLeft > 0 ? '⏭️\nPas ($passLeft)' : '⏭️\nPas yok',
                Colors.blueGrey,
                passLeft > 0 ? _pass : null,
              ),
              const SizedBox(width: 10),
              _actionBtn('✅\nDoğru', Colors.green, _correct),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: SizedBox(
        height: 72,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.85),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: onTap == null ? Colors.white38 : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _roundSummaryView() {
    final teamName = _teamNames[_currentTeam];
    final total = _scores[_currentTeam];
    final reached = _winner != null;
    final deltaColor = _roundDelta > 0
        ? Colors.green
        : (_roundDelta < 0 ? Colors.red : Colors.white70);
    final deltaText = _roundDelta >= 0 ? '+$_roundDelta' : '$_roundDelta';
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('TUR BİTTİ',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 4,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('Bu tur',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 6),
        Text(deltaText,
            style: TextStyle(
                color: deltaColor, fontSize: 56, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('puan',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statBox('✅ Doğru', '$_roundCorrect', Colors.green),
            const SizedBox(width: 10),
            _statBox('❌ Tabu', '$_roundTaboo', Colors.red),
            const SizedBox(width: 10),
            _statBox('⏭️ Pas', '$_roundPassUsed', Colors.blueGrey),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('Toplam',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 2),
              Text('$total / $_targetScore',
                  style: const TextStyle(
                      color: _teal, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _continueFromSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(reached ? 'SONUÇLAR' : 'DEVAM',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _finishedView() {
    final winnerName = _winner != null ? _teamNames[_winner!] : '';
    return Column(
      children: [
        const Spacer(),
        const Text('🏆', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 12),
        const Text('OYUN BİTTİ',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 4,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$winnerName kazandı!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _teal, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_teamCount, (i) {
            final isWinner = i == _winner;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: (isWinner ? _teal : Colors.white)
                    .withValues(alpha: isWinner ? 0.2 : 0.05),
                borderRadius: BorderRadius.circular(14),
                border: isWinner ? Border.all(color: _teal) : null,
              ),
              child: Column(
                children: [
                  Text(_teamNames[i],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${_scores[i]}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _exit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('ANA MENÜ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A24),
        title: const Text('Oyundan çık', style: TextStyle(color: Colors.white)),
        content: const Text('Oyun sonlanacak. Emin misin?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Çık', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) _exit();
  }
}
