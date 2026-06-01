import 'package:flutter/widgets.dart';

/// How a game is physically played.
/// - [multi]  : every player on their own device (1 device = 1 seat).
/// - [single] : one shared device passed around (1 device = N seats).
enum PlayMode { single, multi }

extension PlayModeId on PlayMode {
  String get id => name; // 'single' | 'multi'
  static PlayMode fromId(String id) =>
      PlayMode.values.firstWhere((m) => m.name == id, orElse: () => PlayMode.multi);
}

/// Static, display-level information about a game. The catalog menu is built
/// from these. The canonical source is the in-code [GameRegistry]; Firestore
/// `games/` is an optional future remote override.
class GameMeta {
  final String gameId;
  final String name;
  final String emoji;
  final String description;
  final int minSeats;
  final int maxSeats;
  final Set<PlayMode> supportedModes;
  final bool enabled;

  const GameMeta({
    required this.gameId,
    required this.name,
    required this.emoji,
    required this.description,
    required this.minSeats,
    required this.maxSeats,
    required this.supportedModes,
    this.enabled = true,
  });

  bool get supportsBothModes => supportedModes.length > 1;
}

/// Everything a resolver needs to act on one match. Carries identifiers and
/// config; the resolver reads/writes Firestore itself.
class MatchContext {
  final String roomCode;
  final String matchId;
  final PlayMode mode;

  /// Game-specific lobby settings (e.g. {'gameMode': 'classic'}).
  final Map<String, dynamic> config;

  const MatchContext({
    required this.roomCode,
    required this.matchId,
    required this.mode,
    this.config = const {},
  });
}

/// The authority seam. Today every implementation runs client-side (host
/// device). The interface is intentionally backend-agnostic so a future
/// server implementation (e.g. Supabase Edge Functions) can replace it
/// without touching UI or platform code.
abstract class GameResolver {
  /// Assign secret state (roles) and write the initial match document.
  /// Called once by the host when the match starts.
  Future<void> startMatch(MatchContext ctx, List<String> seatIds);

  /// Validate and record a single seat's action for the current phase.
  Future<void> submitAction(
    MatchContext ctx,
    String seatId,
    Map<String, dynamic> action,
  );

  /// Resolve the current phase and advance match state. Host-only; must be
  /// idempotent / guarded against double-resolution.
  Future<void> resolvePhase(MatchContext ctx);
}

/// A pluggable game. Adding a new game = implementing this + registering it.
abstract class GameDefinition {
  GameMeta get meta;
  GameResolver get resolver;

  /// Optional game-specific lobby settings UI (e.g. classic vs eccentric).
  /// [config] is the mutable settings map; call [onChanged] after mutating.
  Widget? buildLobbyConfig(
    BuildContext context,
    Map<String, dynamic> config,
    VoidCallback onChanged,
  ) =>
      null;

  /// Default game-specific config written to the room on creation.
  Map<String, dynamic> defaultConfig() => const {};

  /// The in-match screen for a given seat (the player viewing it).
  Widget buildMatchScreen(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  });

  /// Private role/secret reveal for a seat (pass-the-phone or own device).
  Widget buildRoleReveal(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  });
}
