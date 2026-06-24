import 'package:app/games/despair/game_logic.dart';
import 'package:app/util/goal_bar.dart';
import 'package:app/util/grid_tile.dart';
import 'package:app/util/responsive_grid.dart';
import 'package:app/util/status_text.dart';
import 'package:app/util/rules_tile.dart';
import 'package:app/util/settings_tile.dart';
import 'package:flutter/material.dart' hide GridTile;

/// Main in-game level screen for the current Despair prototype.
///
/// This file is intentionally thin — it owns only game state and turn logic.
/// All visual widgets are delegated to their own files:
///   - [GoalBar]        → goal_bar.dart
///   - [StatusText]     → status_text.dart
///   - [GridTile]       → grid_tile.dart
///   - [ResponsiveGrid] → responsive_grid.dart
class LevelPageFormat extends StatefulWidget {
  const LevelPageFormat({
    super.key,
    required this.board,
    required this.goal,
    required this.no,
    required this.id,
    required this.hasHint,
    required this.isTut,
  });

  final List<List<String>> board;
  final Map<String, int> goal;
  final int no;
  final int id;
  final bool hasHint;
  final bool isTut;

  @override
  State<LevelPageFormat> createState() => _LevelPageFormatState();
}

class _LevelPageFormatState extends State<LevelPageFormat> {
  final Map<String, GlobalKey> goalKeys = {
    'red': GlobalKey(),
    'blue': GlobalKey(),
    'yellow': GlobalKey(),
  };
  String tileId(int col, int row) => '$col-$row';

  final Map<String, GlobalKey> tileKeys = {};

  late GameViewState _gameState;
  bool _isResolvingTurn = false;

  @override
  void initState() {
    super.initState();

    for (int col = 0; col < widget.board.length; col++) {
      for (int row = 0; row < widget.board[col].length; row++) {
        tileKeys[tileId(col, row)] = GlobalKey();
      }
    }
    _gameState = GameViewState(
      board: cloneBoard(widget.board),
      goal: cloneGoal(widget.goal),
      pendingTurn: PendingTurn.empty,
      requiredStartColor: null,
      status: GameStatus.playing,
      winnerColor: null,
    );
  }

  /// Resolves a completed turn and updates game state immediately.
  void _applyResolvedTurn(PendingTurn pendingTurn) {
    final TurnResult turnResult = resolveTurn(
      GameViewState(
        board: _gameState.board,
        goal: _gameState.goal,
        pendingTurn: pendingTurn,
        requiredStartColor: _gameState.requiredStartColor,
        status: _gameState.status,
        winnerColor: _gameState.winnerColor,
      ),
    );
    setState(() {
      _gameState = GameViewState(
        board: turnResult.board,
        goal: turnResult.goal,
        pendingTurn: PendingTurn.empty,
        requiredStartColor: turnResult.requiredStartColor,
        status: turnResult.status,
        winnerColor: turnResult.winnerColor,
      );
      _isResolvingTurn = false;
    });
  }

  void _onTileTap(int col, int row) {
    if (_isResolvingTurn) return;

    final PendingTurn? nextPendingTurn = tryPickTile(_gameState, col, row);
    if (nextPendingTurn == null) return;

    setState(() {
      _gameState = GameViewState(
        board: _gameState.board,
        goal: _gameState.goal,
        pendingTurn: nextPendingTurn,
        requiredStartColor: _gameState.requiredStartColor,
        status: _gameState.status,
        winnerColor: _gameState.winnerColor,
      );
    });

    if (nextPendingTurn.picks.length == kGameColors.length) {
      setState(() => _isResolvingTurn = true);
      _applyResolvedTurn(nextPendingTurn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2E2E7),
        surfaceTintColor: const Color(0xFFE2E2E7),
        title: Text(
          'Level ${widget.no}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) => const RulesTile(),
              );
            },
            icon: const Icon(Icons.question_mark_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) => const Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.all(12),
                  child: SettingsTile(),
                ),
              );
            },
            icon: const Icon(Icons.settings, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            children: [
              Center(
                child: GoalBar(goal: _gameState.goal, goalKeys: goalKeys),
              ),
              const SizedBox(height: 22),
              StatusText(
                status: _gameState.status,
                requiredStartColor: _gameState.requiredStartColor,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 92),
                  child: ResponsiveGrid(
                    gameState: _gameState,
                    isResolvingTurn: _isResolvingTurn,
                    onTileTap: _onTileTap,
                    tileKeys: tileKeys,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
