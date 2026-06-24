import 'package:app/games/despair/game_logic.dart';
import 'package:flutter/material.dart';

/// One-line prompt shown below the goal bar.
///
/// During play it tells the player which colour to start with (or "any colour"
/// if there is no constraint). On game over it shows "You Win" or "You Lose".
class StatusText extends StatelessWidget {
  const StatusText({
    super.key,
    required this.status,
    required this.requiredStartColor,
  });

  final GameStatus status;
  final String? requiredStartColor;

  String _statusText() {
    switch (status) {
      case GameStatus.won:
        return 'You Win';
      case GameStatus.lost:
        return 'You Lose';
      case GameStatus.playing:
        if (requiredStartColor == null) {
          return 'Select any colour';
        }
        return 'Start with $requiredStartColor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _statusText(),
      style: TextStyle(
        fontSize: 18,
        fontWeight: status == GameStatus.playing
            ? FontWeight.w500
            : FontWeight.w700,
        color: status == GameStatus.playing ? Colors.black54 : Colors.black,
      ),
    );
  }
}
