import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_l10n.dart';
import '../../models/room.dart';
import '../../models/seat.dart';
import '../../services/room_service.dart';
import '../../screens/widgets/role_info_dialog.dart';
import '../../screens/widgets/game_time_display.dart';
import '../../screens/widgets/dead_chat_sheet.dart';
import 'vampir_match.dart';
import 'vampir_resolver.dart';
import 'vampir_end_screen.dart';

/// Multi-phone Vampir Köylü match screen. The viewer owns exactly one seat
/// (seatId == their uid). Roles are read from the viewer's own private doc;
/// other seats' roles stay hidden (except vampire teammates, listed in the
/// viewer's private `team`).
class VampirMatchScreen extends StatefulWidget {
  final String roomCode;
  final String matchId;
  final String seatId;

  const VampirMatchScreen({
    super.key,
    required this.roomCode,
    required this.matchId,
    required this.seatId,
  });

  @override
  State<VampirMatchScreen> createState() => _VampirMatchScreenState();
}

class _VampirMatchScreenState extends State<VampirMatchScreen> {
  final _resolver = VampirResolver();
  bool _revealed = false;

  int? _shownNightResult;
  String? _shownEliminatedId;
  int? _shownTieTimestamp;
  int? _botActedNight;
  int? _botVotedRound;
  bool _navigatedToEnd = false;

  DocumentReference<Map<String, dynamic>> get _privateRef => FirebaseFirestore
      .instance
      .collection('rooms')
      .doc(widget.roomCode)
      .collection('matches')
      .doc(widget.matchId)
      .collection('private')
      .doc(widget.seatId);

  // ---- action helpers ------------------------------------------------------

  Future<void> _submitNight(VampirMatch match, String target,
      {Map<String, dynamic>? extra}) async {
    await _resolver.submitNight(
        widget.roomCode, widget.matchId, widget.seatId, target, match.nightNumber);
    if (extra != null && extra.isNotEmpty) {
      await _privateRef.set(extra, SetOptions(merge: true));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppL10n.actionSubmitted),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _submitVote(VampirMatch match, String target) async {
    await _resolver.submitVote(
        widget.roomCode, widget.matchId, widget.seatId, target, match.voteRound);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppL10n.voteSubmitted),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ---- popups --------------------------------------------------------------

  void _popup(String emoji, String label, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.4),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppL10n.ok,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShowPopups(
      VampirMatch match, VampirPrivate priv, Map<String, Seat> seats) {
    String nameOf(String? id) =>
        id == null ? AppL10n.unknown_ : (seats[id]?.displayName ?? AppL10n.unknown_);

    // Night result
    final nr = match.nightResults;
    if (nr != null) {
      final n = nr['nightNumber'] as int?;
      if (n != null && n != _shownNightResult) {
        _shownNightResult = n;
        final killedId = nr['killed'] as String?;
        final messages = <String>[];
        if (killedId != null) {
          final dm = AppL10n.deathMessages(nameOf(killedId));
          messages.add(dm[Random().nextInt(dm.length)]);
        } else {
          final pm = AppL10n.peaceMessages;
          messages.add(pm[Random().nextInt(pm.length)]);
        }
        final asikEffect = nr['asik_effect'] as String?;
        if (asikEffect == 'intihar') messages.add(AppL10n.asikIntihar);
        if (asikEffect == 'kinlendi') messages.add(AppL10n.asikKinlendi);
        if (asikEffect == 'deli_devir') messages.add(AppL10n.asikDeli);
        final kinlendiKill = nr['kinlendi_kill'] as String?;
        if (kinlendiKill != null) {
          messages.add(AppL10n.asikVengeance(nameOf(kinlendiKill)));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _popup(killedId != null ? '🩸' : '🌙', AppL10n.morningNews,
                messages.join('\n'), killedId != null ? Colors.red.shade300 : Colors.green.shade300);
          }
        });
      }
    }

    // Elimination
    final le = match.lastEliminated;
    if (le != null) {
      final id = le['id'] as String?;
      if (id != null && id != _shownEliminatedId) {
        _shownEliminatedId = id;
        final msgs = AppL10n.eliminatedMessages(nameOf(id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _popup('⚖️', AppL10n.voteResult,
                msgs[Random().nextInt(msgs.length)], Colors.red.shade300);
          }
        });
      }
    }

    // Tie
    final tie = match.lastTie;
    if (tie != null) {
      final ts = (tie['timestamp'] as Timestamp?)?.millisecondsSinceEpoch;
      if (ts != null && ts != _shownTieTimestamp) {
        _shownTieTimestamp = ts;
        final ids = List<String>.from(tie['tiedPlayerIds'] ?? []);
        final names = ids.map(nameOf).toList();
        final tm = AppL10n.tieMessages;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && names.isNotEmpty) {
            _popup('⚖️', AppL10n.voteResult,
                '${tm[Random().nextInt(tm.length)]}\n${AppL10n.tiedPlayersJoin(names)}',
                Colors.amber);
          }
        });
      }
    }
  }

  void _maybeBotActions(VampirMatch match, bool isHost) {
    if (!isHost) return;
    if (match.phase == VampirPhase.night && _botActedNight != match.nightNumber) {
      _botActedNight = match.nightNumber;
      Future.delayed(const Duration(milliseconds: 500),
          () => _resolver.autoSubmitBotNight(widget.roomCode, widget.matchId));
    }
    if (match.phase == VampirPhase.day &&
        match.votingStarted &&
        _botVotedRound != match.voteRound) {
      _botVotedRound = match.voteRound;
      Future.delayed(const Duration(milliseconds: 300),
          () => _resolver.autoSubmitBotVotes(widget.roomCode, widget.matchId));
    }
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room>(
      stream: RoomService.watchRoom(widget.roomCode),
      builder: (context, roomSnap) {
        if (!roomSnap.hasData) return _loading();
        final room = roomSnap.data!;
        return StreamBuilder<VampirMatch>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomCode)
              .collection('matches')
              .doc(widget.matchId)
              .snapshots()
              .map((d) => VampirMatch.fromDoc(d)),
          builder: (context, matchSnap) {
            if (!matchSnap.hasData) return _loading();
            final match = matchSnap.data!;

            if (match.isFinished && !_navigatedToEnd) {
              _navigatedToEnd = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VampirEndScreen(
                      roomCode: widget.roomCode,
                      matchId: widget.matchId,
                      seatId: widget.seatId,
                    ),
                  ),
                );
              });
              return _loading();
            }

            return StreamBuilder<VampirPrivate>(
              stream: _privateRef.snapshots().map((d) => VampirPrivate.fromDoc(d)),
              builder: (context, privSnap) {
                if (!privSnap.hasData) return _loading();
                final priv = privSnap.data!;
                return _buildBoard(room, match, priv);
              },
            );
          },
        );
      },
    );
  }

  Widget _loading() => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFDC143C))),
      );

  Widget _buildBoard(Room room, VampirMatch match, VampirPrivate priv) {
    final seats = room.seats;
    final isHost = widget.seatId == room.hostUid;
    final myRole = priv.role;
    final roleColor = vampirRoleColor(myRole);

    if (!_revealed) return _revealGate(myRole, roleColor);

    _maybeShowPopups(match, priv, seats);
    _maybeBotActions(match, isHost);

    final isNight = match.phase == VampirPhase.night;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.roomLabel(widget.roomCode)),
        backgroundColor: const Color(0xFF8B0000),
        automaticallyImplyLeading: false,
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
        child: SafeArea(
          child: Column(
            children: [
              // Phase header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isNight ? '🌙' : '☀️',
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isNight ? AppL10n.night : AppL10n.day,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        GameTimeDisplay(
                          phaseStartTimestamp:
                              match.phase == VampirPhase.day && !match.votingStarted
                                  ? match.phaseStartTimestamp
                                  : null,
                          staticTime:
                              match.phase == VampirPhase.day && match.votingStarted
                                  ? '09:00'
                                  : match.phaseTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),

              if (isHost) _hostPanel(match),

              _roleCard(myRole, roleColor),

              // Detective private result
              if (priv.dedektifResult != null &&
                  priv.dedektifResultTarget != null)
                _dedektifResultCard(priv, seats),

              // Player list
              Expanded(child: _playerList(match, priv, seats)),

              // Action button
              _actionArea(match, priv, seats, roleColor, isHost),
            ],
          ),
        ),
      ),
    );
  }

  // ---- reveal gate ---------------------------------------------------------

  Widget _revealGate(String role, Color color) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A1A), color.withValues(alpha: 0.3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 350,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(vampirRoleIcon(role),
                            style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 20),
                        Text(
                          AppL10n.roleNames[role] ?? AppL10n.unknown,
                          style: TextStyle(
                              color: color,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => setState(() => _revealed = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(AppL10n.continue_,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- host panel ----------------------------------------------------------

  Widget _hostPanel(VampirMatch match) {
    if (match.phase == VampirPhase.night) {
      return _panelBox(Colors.purple, AppL10n.hostControlPanel, AppL10n.endNight,
          () async {
        final ok = await _resolver.areAllNightActionsSubmitted(
            widget.roomCode, widget.matchId);
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppL10n.notAllActed),
              backgroundColor: Colors.orange));
          return;
        }
        await _resolver.resolveNight(widget.roomCode, widget.matchId);
      });
    }
    // Day
    final color = match.votingStarted ? Colors.orange : Colors.indigo;
    final title = match.votingStarted ? AppL10n.votingPhase : AppL10n.freeTime;
    final btn = match.votingStarted ? AppL10n.endVoting : AppL10n.startNight;
    return _panelBox(color, title, btn, () async {
      if (match.votingStarted) {
        await _resolver.resolveDay(widget.roomCode, widget.matchId);
      } else {
        await _resolver.advanceToNight(widget.roomCode, widget.matchId);
      }
    });
  }

  Widget _panelBox(
      Color color, String title, String btnLabel, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.shield, color: color),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(btnLabel,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- role card -----------------------------------------------------------

  Widget _roleCard(String role, Color color) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Text(vampirRoleIcon(role), style: const TextStyle(fontSize: 50)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppL10n.myRole,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                Text(AppL10n.roleNames[role] ?? AppL10n.unknown,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 2)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => RoleInfoDialog(role: role),
            ),
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _dedektifResultCard(VampirPrivate priv, Map<String, Seat> seats) {
    final targetName =
        seats[priv.dedektifResultTarget]?.displayName ?? AppL10n.unknown_;
    final roleName = AppL10n.getRoleDisplayName(priv.dedektifResult!);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Text('🔍 ${AppL10n.dedektifResult(targetName, roleName)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
    );
  }

  // ---- player list ---------------------------------------------------------

  Widget _playerList(VampirMatch match, VampirPrivate priv, Map<String, Seat> seats) {
    final ids = match.seatIds.toList()
      ..sort((a, b) => (match.deadSeats.contains(a) ? 1 : 0)
          .compareTo(match.deadSeats.contains(b) ? 1 : 0));
    final aliveCount = match.seatIds.where((s) => match.isAlive(s)).length;
    final amVampire = priv.role == 'vampir';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppL10n.playersAlive(aliveCount, match.seatIds.length),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, i) {
                final id = ids[i];
                final seat = seats[id];
                final name = seat?.displayName ?? id;
                final color = _seatColor(seat);
                final isDead = match.deadSeats.contains(id);
                final teammate = amVampire && priv.team.contains(id) && id != widget.seatId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration:
                                  isDead ? TextDecoration.lineThrough : null),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDead ? Colors.white38 : Colors.white,
                                decoration:
                                    isDead ? TextDecoration.lineThrough : null)),
                      ),
                      if (teammate)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.shade700, width: 1),
                          ),
                          child: const Text('🧛', style: TextStyle(fontSize: 14)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDead ? Colors.red : Colors.green)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDead ? Colors.red : Colors.green,
                              width: 1),
                        ),
                        child: Text(isDead ? AppL10n.dead : AppL10n.alive,
                            style: TextStyle(
                                color: isDead ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _seatColor(Seat? seat) {
    if (seat == null) return Colors.grey;
    try {
      return Color(int.parse(seat.avatarColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ---- action area ---------------------------------------------------------

  Widget _actionArea(VampirMatch match, VampirPrivate priv,
      Map<String, Seat> seats, Color roleColor, bool isHost) {
    final isAlive = match.isAlive(widget.seatId);

    if (!isAlive) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _box(AppL10n.deadPlayerMsg, Colors.red),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeadChat(seats),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                icon: const Text('💀'),
                label: Text(AppL10n.deadChat,
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (match.phase == VampirPhase.night) {
      return _nightAction(match, priv, seats, roleColor);
    }
    return _dayAction(match, priv, seats);
  }

  Future<bool> _hasNightSubmission() async {
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('matches')
        .doc(widget.matchId)
        .collection('actions')
        .doc(widget.seatId)
        .get();
    return doc.data()?['nightRound'] != null;
  }

  Widget _nightAction(VampirMatch match, VampirPrivate priv,
      Map<String, Seat> seats, Color roleColor) {
    final myRole = priv.role;

    // Roles with no night action
    if (myRole == 'koylu' || myRole == 'deli' || myRole == 'manipulator') {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _box(AppL10n.noNightAction, Colors.blue),
      );
    }

    // Detective already used their one-time ability
    if (myRole == 'dedektif' && priv.dedektifUsed) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _box(AppL10n.dedektifUsed, Colors.purple),
      );
    }

    // Âşık special handling
    if (myRole == 'asik') {
      if (priv.asikTarget != null && !priv.asikKinlendi) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _box(AppL10n.asikTargetSelected, Colors.pink),
        );
      }
    }

    return FutureBuilder<bool>(
      future: _hasNightSubmission(),
      builder: (context, snap) {
        final submitted = snap.data ?? false;
        if (submitted) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: _box(AppL10n.actionSent, Colors.green),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _openTargetSheet(match, priv, seats, roleColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                  myRole == 'asik'
                      ? AppL10n.asikSelectTarget
                      : AppL10n.selectTarget,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  void _openTargetSheet(VampirMatch match, VampirPrivate priv,
      Map<String, Seat> seats, Color roleColor) {
    final myRole = priv.role;
    final targets = match.seatIds.where((id) {
      if (id == widget.seatId) {
        // Doctor may self-protect once; nobody else targets self.
        return myRole == 'doktor' && !priv.selfProtectUsed;
      }
      return match.isAlive(id);
    }).toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.noTargets), backgroundColor: Colors.orange));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppL10n.selectTarget,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            ...targets.map((id) {
              final seat = seats[id];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final extra = <String, dynamic>{};
                    if (myRole == 'doktor' && id == widget.seatId) {
                      extra['selfProtectUsed'] = true;
                    }
                    _submitNight(match, id, extra: extra);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F1F),
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 20,
                        backgroundColor: _seatColor(seat),
                        child: Text(
                            (seat?.displayName ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(seat?.displayName ?? id,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _dayAction(
      VampirMatch match, VampirPrivate priv, Map<String, Seat> seats) {
    if (!match.votingStarted) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _box(AppL10n.freeTimeBox, Colors.indigo),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('matches')
          .doc(widget.matchId)
          .collection('actions')
          .doc(widget.seatId)
          .get(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final voted = data != null && data['voteRound'] == match.voteRound;
        if (voted) {
          final targetName = seats[data['dayVote']]?.displayName ?? AppL10n.unknown_;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: _box('${AppL10n.voteGiven}\n${AppL10n.voteTargetLabel}$targetName',
                Colors.orange),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _openVoteSheet(match, seats),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(AppL10n.doVote,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  void _openVoteSheet(VampirMatch match, Map<String, Seat> seats) {
    final tiedIds = (match.lastTie != null && match.votingStarted)
        ? List<String>.from(match.lastTie!['tiedPlayerIds'] ?? [])
        : <String>[];
    final targets = match.seatIds
        .where((id) => match.isAlive(id) && id != widget.seatId)
        .toList()
      ..sort((a, b) => (tiedIds.contains(a) ? 0 : 1)
          .compareTo(tiedIds.contains(b) ? 0 : 1));

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.noVoteTargets), backgroundColor: Colors.orange));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppL10n.voteQuestion,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            ...targets.map((id) {
              final seat = seats[id];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitVote(match, id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F1F),
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 20,
                        backgroundColor: _seatColor(seat),
                        child: Text(
                            (seat?.displayName ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Text(seat?.displayName ?? id,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDeadChat(Map<String, Seat> seats) {
    final playersLike = {
      for (final e in seats.entries)
        e.key: {
          'username': e.value.displayName,
          'avatarColor': e.value.avatarColor,
        }
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeadChatSheet(
        roomCode: widget.roomCode,
        userId: widget.seatId,
        players: playersLike,
      ),
    );
  }

  Widget _box(String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      );
}
