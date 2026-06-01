import 'package:cloud_firestore/cloud_firestore.dart';
import '../game_definition.dart';

/// Tabu is a single-device, pass-the-phone game: all scoring and timing happen
/// locally in [TabuMatchScreen]. The resolver only needs to stamp an initial
/// match document so the platform's lobby → match transition works.
class TabuResolver implements GameResolver {
  static final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _matchRef(String code, String matchId) =>
      _db.collection('rooms').doc(code).collection('matches').doc(matchId);

  @override
  Future<void> startMatch(MatchContext ctx, List<String> seatIds) async {
    await _matchRef(ctx.roomCode, ctx.matchId).set({
      'gameId': 'tabu',
      'phase': 'playing',
      'config': ctx.config,
      'seatIds': seatIds,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> submitAction(
    MatchContext ctx,
    String seatId,
    Map<String, dynamic> action,
  ) async {}

  @override
  Future<void> resolvePhase(MatchContext ctx) async {}
}
