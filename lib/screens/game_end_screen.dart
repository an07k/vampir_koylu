import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_l10n.dart';
import '../services/auth_service.dart';
import 'room_lobby_screen.dart';

class GameEndScreen extends StatefulWidget {
  final String roomCode;

  const GameEndScreen({super.key, required this.roomCode});

  @override
  State<GameEndScreen> createState() => _GameEndScreenState();
}

class _GameEndScreenState extends State<GameEndScreen> {
  String? _userId;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _userId = user['userId']);
    }
  }

  Future<void> _resetRoomAndReturn(Map<String, dynamic> players) async {
    if (_isReturning) return;
    setState(() => _isReturning = true);

    try {
      final updatedPlayers = <String, dynamic>{};
      players.forEach((id, data) {
        final playerData = Map<String, dynamic>.from(data);
        playerData.remove('role');
        updatedPlayers[id] = playerData;
      });

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({
        'gameState': 'waiting',
        'currentPhase': 'night',
        'deadPlayers': [],
        'nightActions': {},
        'dayVotes': {},
        'votingStarted': false,
        'nightNumber': 1,
        'players': updatedPlayers,
        'winner': FieldValue.delete(),
        'winnerIds': FieldValue.delete(),
        'lastEliminated': FieldValue.delete(),
        'phaseStartTimestamp': FieldValue.delete(),
        'nightResults': FieldValue.delete(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RoomLobbyScreen(roomCode: widget.roomCode)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReturning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.errorMsg(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _returnToRoom() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => RoomLobbyScreen(roomCode: widget.roomCode)),
    );
  }

  void _goToMainMenu() {
    Navigator.pushNamedAndRemoveUntil(
        context, '/main-menu', (route) => false);
  }

  Map<String, dynamic> _getWinnerInfo(String winner) {
    switch (winner) {
      case 'vampir':
        return {
          'icon': '🧛',
          'title': AppL10n.vampireWin,
          'subtitle': AppL10n.vampireWinSub,
          'color': const Color(0xFFDC143C),
        };
      case 'koylu':
        return {
          'icon': '👨‍🌾',
          'title': AppL10n.villagerWin,
          'subtitle': AppL10n.villagerWinSub,
          'color': const Color(0xFF32CD32),
        };
      case 'deli':
        return {
          'icon': '🤪',
          'title': AppL10n.madWin,
          'subtitle': AppL10n.madWinSub,
          'color': const Color(0xFFFF8C00),
        };
      default:
        return {
          'icon': '❓',
          'title': AppL10n.gameOver,
          'subtitle': AppL10n.unknownResult,
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(AppL10n.roomNotFoundMsg,
                  style: const TextStyle(color: Colors.white)),
            );
          }

          final roomData =
              snapshot.data!.data() as Map<String, dynamic>;
          final winner = roomData['winner'] ?? 'unknown';
          final winnerIds =
              List<String>.from(roomData['winnerIds'] ?? []);
          final players =
              Map<String, dynamic>.from(roomData['players'] ?? {});
          final hostId = roomData['hostId'];
          final isHost = _userId == hostId;
          final winnerInfo = _getWinnerInfo(winner);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1A1A),
                  (winnerInfo['color'] as Color).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(winnerInfo['icon'],
                      style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 20),
                  Text(
                    winnerInfo['title'],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: winnerInfo['color'],
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    winnerInfo['subtitle'],
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // Kazanan oyuncular
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (winnerInfo['color'] as Color)
                            .withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppL10n.winners,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: winnerInfo['color'],
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...winnerIds.map((playerId) {
                          final playerData = players[playerId];
                          if (playerData == null) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                      playerData['avatarColor']
                                          .replaceFirst('#', '0xFF'),
                                    )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      playerData['username'][0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    playerData['username'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.amber, width: 1),
                                  ),
                                  child: const Text(
                                    '💰 +10',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Butonlar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isReturning
                                ? null
                                : () => isHost
                                    ? _resetRoomAndReturn(players)
                                    : _returnToRoom(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: winnerInfo['color'],
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(15)),
                            ),
                            icon: _isReturning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.meeting_room,
                                    color: Colors.white),
                            label: Text(
                              _isReturning
                                  ? AppL10n.returning
                                  : AppL10n.returnToRoomBtn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (!isHost) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _goToMainMenu,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF3A3A3A),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(15)),
                              ),
                              child: Text(
                                AppL10n.mainMenu,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
