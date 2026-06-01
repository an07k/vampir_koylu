import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../games/game_definition.dart';
import '../games/game_registry.dart';
import '../models/room.dart';
import '../models/seat.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';

class PlatformLobbyScreen extends StatefulWidget {
  final String roomCode;
  const PlatformLobbyScreen({super.key, required this.roomCode});

  @override
  State<PlatformLobbyScreen> createState() => _PlatformLobbyScreenState();
}

class _PlatformLobbyScreenState extends State<PlatformLobbyScreen> {
  String? _uid;
  bool _navigated = false;
  bool _starting = false;

  static const _palette = [
    '#DC143C', '#1E90FF', '#32CD32', '#9370DB', '#FF8C00', '#FFD700',
  ];

  @override
  void initState() {
    super.initState();
    AuthService.getCurrentUser().then((u) {
      if (mounted) setState(() => _uid = u?['userId']);
    });
  }

  void _maybeEnterMatch(Room room) {
    if (_navigated || room.status != RoomStatus.inMatch) return;
    final matchId = room.currentMatchId;
    if (matchId == null) return;
    final game = GameRegistry.byId(room.gameId);
    if (game == null) return;
    _navigated = true;
    final seatId = _uid ?? room.seats.keys.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => game.buildMatchScreen(
            context,
            roomCode: widget.roomCode,
            matchId: matchId,
            seatId: seatId,
          ),
        ),
      );
    });
  }

  Future<void> _start(Room room) async {
    setState(() => _starting = true);
    try {
      await RoomService.startMatch(widget.roomCode);
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Başlatılamadı'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addLocalSeat() async {
    final nameController = TextEditingController();
    String color = _palette.first;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Oyuncu ekle', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'İsim',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: _palette.map((c) {
                  final sel = c == color;
                  return GestureDetector(
                    onTap: () => setSt(() => color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? Colors.white : Colors.transparent, width: 3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal', style: TextStyle(color: Colors.white54))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ekle', style: TextStyle(color: AppColors.secondary))),
          ],
        ),
      ),
    );
    if (added == true && nameController.text.trim().isNotEmpty && _uid != null) {
      final err = await RoomService.addLocalSeat(
        code: widget.roomCode,
        hostUid: _uid!,
        displayName: nameController.text.trim(),
        avatarColor: color,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.roomCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oda kodu kopyalandı: ${widget.roomCode}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Widget _codeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Oda Kodu',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                widget.roomCode,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Kopyala',
            onPressed: _copyCode,
            icon: const Icon(Icons.copy, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Future<void> _leave(Room room, bool isHost) async {
    if (isHost) {
      await RoomService.closeRoom(widget.roomCode);
    } else if (_uid != null) {
      await RoomService.removeSeat(code: widget.roomCode, seatId: _uid!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room>(
      stream: RoomService.watchRoom(widget.roomCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.secondary)));
        }
        final room = snapshot.data!;
        _maybeEnterMatch(room);

        final isHost = _uid != null && _uid == room.hostUid;
        final game = GameRegistry.byId(room.gameId);
        final minSeats = game?.meta.minSeats ?? 0;
        final canStart = isHost && room.seatCount >= minSeats;
        final isSingle = room.mode == PlayMode.single;

        return Scaffold(
          appBar: AppBar(
            title: Text('Oda ${room.roomCode}'),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: Icon(isHost ? Icons.close : Icons.logout),
                onPressed: () => _leave(room, isHost),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, Color(0x4D8B0000)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (!isSingle) _codeCard(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${room.seatCount}/${room.maxSeats} oyuncu • '
                      '${isSingle ? 'Tek telefon' : 'Herkes kendi'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: room.seats.values
                          .map((s) => _seatTile(s, isHost))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (isHost && isSingle && !room.isFull)
                          OutlinedButton.icon(
                            onPressed: _addLocalSeat,
                            icon: const Icon(Icons.person_add, color: Colors.white),
                            label: const Text('Oyuncu ekle',
                                style: TextStyle(color: Colors.white)),
                          ),
                        if (isHost) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (canStart && !_starting) ? () => _start(room) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: _starting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      canStart
                                          ? 'OYUNU BAŞLAT'
                                          : 'En az $minSeats oyuncu gerek',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                            ),
                          ),
                        ] else
                          const Text('Host\'un başlatması bekleniyor...',
                              style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _seatTile(Seat seat, bool viewerIsHost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(int.parse(seat.avatarColor.replaceFirst('#', '0xFF'))),
            child: Text(
              seat.displayName.isNotEmpty ? seat.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(seat.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          if (seat.isHost)
            const Icon(Icons.star, color: AppColors.accent, size: 20),
          if (viewerIsHost && !seat.isHost)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
              onPressed: () =>
                  RoomService.removeSeat(code: widget.roomCode, seatId: seat.seatId),
            ),
        ],
      ),
    );
  }
}
