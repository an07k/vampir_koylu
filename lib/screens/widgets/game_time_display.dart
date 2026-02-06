import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameTimeDisplay extends StatefulWidget {
  final Timestamp? phaseStartTimestamp;
  final String staticTime;

  const GameTimeDisplay({
    super.key,
    required this.phaseStartTimestamp,
    required this.staticTime,
  });

  @override
  State<GameTimeDisplay> createState() => _GameTimeDisplayState();
}

class _GameTimeDisplayState extends State<GameTimeDisplay> {
  Timer? _timer;
  String _displayTime = '09:00';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(GameTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phaseStartTimestamp != oldWidget.phaseStartTimestamp) {
      _updateTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    if (widget.phaseStartTimestamp == null) {
      setState(() {
        _displayTime = widget.staticTime;
      });
      return;
    }

    // Calculate elapsed real seconds
    final now = DateTime.now();
    final phaseStart = widget.phaseStartTimestamp!.toDate();
    final elapsedSeconds = now.difference(phaseStart).inSeconds;

    // Convert to game minutes: 3 real seconds = 5 game minutes
    final elapsedGameMinutes = (elapsedSeconds / 3 * 5).toInt();

    // Start at 09:00 (540 minutes from midnight)
    final startMinutes = 9 * 60; // 540
    final currentGameMinutes = startMinutes + elapsedGameMinutes;

    // Cap at 22:00 (1320 minutes)
    final maxMinutes = 22 * 60; // 1320
    final cappedMinutes =
        currentGameMinutes > maxMinutes ? maxMinutes : currentGameMinutes;

    // Round to nearest 30 minutes (09:00, 09:30, 10:00, 10:30, ...)
    final roundedMinutes = (cappedMinutes ~/ 30) * 30;

    // Convert back to HH:MM format
    final hours = (roundedMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (roundedMinutes % 60).toString().padLeft(2, '0');

    setState(() {
      _displayTime = '$hours:$minutes';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Saat: $_displayTime',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
    );
  }
}
