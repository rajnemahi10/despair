import 'dart:math' as math;

import 'package:app/games/despair/game_logic.dart';
import 'package:app/util/rules_tile.dart';
import 'package:app/util/settings_tile.dart';
import 'package:flutter/material.dart';

/// Main in-game level screen for the current Despair prototype.
///
/// Responsibilities in this file:
/// - render the responsive board and goal bar
/// - keep maps of measured on-screen tile centers for later animation work
/// - translate taps into rule-checked game-logic actions
/// - run the "stack then fly to goal" animation before applying a finished turn
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

class _LevelPageFormatState extends State<LevelPageFormat>
    with SingleTickerProviderStateMixin {
  static const List<String> _goalOrder = <String>['red', 'blue', 'yellow'];
  static const double _selectedTileScale = 1.14;

  // The UI always stores and resolves actual tile/goal positions by center
  // points in screen coordinates because later animations are easier to drive
  // center-to-center than top-left to top-left.
  late Map<String, GlobalKey> _gridTileKeys;
  late Map<String, GlobalKey> _goalSquareKeys;

  late GameViewState _gameState;
  late final AnimationController _stackFlightController;

  Map<String, Offset> _gridTileCenters = <String, Offset>{};
  Map<String, Offset> _goalSquareCenters = <String, Offset>{};

  // The overlay animation uses its own frozen snapshot of the picked tiles.
  // While the overlay is active, the real board tiles are hidden underneath it.
  List<_AnimatedStackTile> _animatedTiles = <_AnimatedStackTile>[];
  Set<String> _hiddenGridTileKeys = <String>{};

  bool _isAnimatingTurn = false;
  double _lastTileSize = 48;

  @override
  void initState() {
    super.initState();
    _gameState = GameViewState(
      board: cloneBoard(widget.board),
      goal: cloneGoal(widget.goal),
      pendingTurn: PendingTurn.empty,
      requiredStartColor: null,
      status: GameStatus.playing,
      winnerColor: null,
    );
    _stackFlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _buildMeasurementKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureCenters());
  }

  @override
  void dispose() {
    _stackFlightController.dispose();
    super.dispose();
  }

  String _gridTileKey(int col, int row) => '$col-$row';

  void _buildMeasurementKeys() {
    _gridTileKeys = <String, GlobalKey>{};
    for (int col = 0; col < _gameState.board.length; col += 1) {
      for (int row = 0; row < _gameState.board[col].length; row += 1) {
        _gridTileKeys[_gridTileKey(col, row)] = GlobalKey();
      }
    }

    _goalSquareKeys = <String, GlobalKey>{
      for (final String color in _goalOrder) color: GlobalKey(),
    };
  }

  Color _colorForName(String colorName) {
    switch (colorName) {
      case 'red':
        return const Color(0xFFFF2B3E);
      case 'blue':
        return const Color(0xFF3F7AE0);
      case 'yellow':
        return const Color(0xFFFFA20A);
      default:
        return Colors.grey;
    }
  }

  Offset? _centerForKey(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context == null) return null;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final Size size = renderObject.size;
    // Measure the actual rendered center point instead of deriving it from the
    // unscaled child size. This is important because selected tiles are drawn
    // through AnimatedScale, so the visual position used by the animation needs
    // to come from the transformed on-screen center, not the original box size.
    return renderObject.localToGlobal(Offset(size.width / 2, size.height / 2));
  }

  bool _mapsMatch(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final String key in a.keys) {
      final Offset? bValue = b[key];
      if (bValue == null || a[key] != bValue) return false;
    }
    return true;
  }

  /// Reads the current actual screen-space centers of all grid tiles and goal
  /// squares from their RenderBoxes.
  ///
  /// The board can rebuild into uneven column heights after every turn, so this
  /// map must always be refreshed after any state change that alters layout.
  void _captureCenters() {
    final Map<String, Offset> nextGridCenters = <String, Offset>{};
    for (final MapEntry<String, GlobalKey> entry in _gridTileKeys.entries) {
      final Offset? center = _centerForKey(entry.value);
      if (center != null) {
        nextGridCenters[entry.key] = center;
      }
    }

    final Map<String, Offset> nextGoalCenters = <String, Offset>{};
    for (final MapEntry<String, GlobalKey> entry in _goalSquareKeys.entries) {
      final Offset? center = _centerForKey(entry.value);
      if (center != null) {
        nextGoalCenters[entry.key] = center;
      }
    }

    if (!_mapsMatch(_gridTileCenters, nextGridCenters) ||
        !_mapsMatch(_goalSquareCenters, nextGoalCenters)) {
      setState(() {
        _gridTileCenters = nextGridCenters;
        _goalSquareCenters = nextGoalCenters;
      });
    }
  }

  void _scheduleCenterCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureCenters());
  }

  /// Turns the current 3 selected tiles into an animation overlay snapshot.
  ///
  /// Animation rules from the user:
  /// - the winning tile stays pinned in its current board position first
  /// - the other two selected tiles move directly from their own positions and
  ///   stack below the winner
  /// - the full stack then flies to the winning goal chip center
  List<_AnimatedStackTile> _buildAnimatedStackTiles(
    PendingTurn pendingTurn,
    String winnerColor,
  ) {
    final PickedTile winnerTile = pendingTurn.picks.firstWhere(
      (PickedTile tile) =>
          tile.col == pendingTurn.primaryCol && tile.color == winnerColor,
    );

    final List<PickedTile> others =
        pendingTurn.picks
            .where((PickedTile tile) => tile.key != winnerTile.key)
            .toList()
          ..sort((PickedTile a, PickedTile b) {
            // Higher row should sit closer to the winner when stacking because it
            // already reads as more "topward" on the board.
            return b.row.compareTo(a.row);
          });

    final List<PickedTile> ordered = <PickedTile>[winnerTile, ...others];
    final double stackPeek = (_lastTileSize * _selectedTileScale) * 0.32;

    return List<_AnimatedStackTile>.generate(ordered.length, (int index) {
      final PickedTile tile = ordered[index];
      final Offset startCenter =
          _gridTileCenters[tile.key] ?? const Offset(-9999, -9999);
      final Offset stackCenter = Offset(
        _gridTileCenters[winnerTile.key]!.dx,
        _gridTileCenters[winnerTile.key]!.dy + (stackPeek * index),
      );

      return _AnimatedStackTile(
        key: tile.key,
        color: tile.color,
        startCenter: startCenter,
        stackCenter: stackCenter,
        stackOrder: index,
      );
    });
  }

  /// Applies a completed turn after its animation has finished.
  void _applyResolvedTurn(PendingTurn pendingTurn) {
    final GameViewState previewState = GameViewState(
      board: _gameState.board,
      goal: _gameState.goal,
      pendingTurn: pendingTurn,
      requiredStartColor: _gameState.requiredStartColor,
      status: _gameState.status,
      winnerColor: _gameState.winnerColor,
    );

    final TurnResult turnResult = resolveTurn(previewState);
    setState(() {
      _gameState = GameViewState(
        board: turnResult.board,
        goal: turnResult.goal,
        pendingTurn: PendingTurn.empty,
        requiredStartColor: turnResult.requiredStartColor,
        status: turnResult.status,
        winnerColor: turnResult.winnerColor,
      );
      _isAnimatingTurn = false;
      _animatedTiles = <_AnimatedStackTile>[];
      _hiddenGridTileKeys = <String>{};
      _buildMeasurementKeys();
    });
    _scheduleCenterCapture();
  }

  /// Runs the stack-and-fly animation for one completed turn.
  ///
  /// The UI intentionally waits for the full motion to complete before
  /// subtracting the goal and rebuilding the board, so the player sees:
  /// board picks -> stack forms -> stack flies -> score updates.
  Future<void> _animateCompletedTurn(PendingTurn pendingTurn) async {
    final String winnerColor = resolveWinnerColor(
      _gameState.board,
      pendingTurn,
    );
    final Offset? goalCenter = _goalSquareCenters[winnerColor];
    final Offset? winnerCenter =
        _gridTileCenters[pendingTurn.picks
            .firstWhere(
              (PickedTile tile) =>
                  tile.col == pendingTurn.primaryCol &&
                  tile.color == winnerColor,
            )
            .key];

    if (goalCenter == null || winnerCenter == null) {
      // If the centers are somehow unavailable, fall back to immediate logical
      // resolution rather than leaving the game stuck.
      _applyResolvedTurn(pendingTurn);
      return;
    }

    final List<_AnimatedStackTile> animatedTiles = _buildAnimatedStackTiles(
      pendingTurn,
      winnerColor,
    );

    setState(() {
      _isAnimatingTurn = true;
      _animatedTiles = animatedTiles;
      _hiddenGridTileKeys = pendingTurn.picks
          .map((PickedTile tile) => tile.key)
          .toSet();
    });

    await _stackFlightController.forward(from: 0);
    if (!mounted) return;
    _applyResolvedTurn(pendingTurn);
  }

  Future<void> _onTileTap(int col, int row) async {
    if (_isAnimatingTurn) return;

    final PendingTurn? nextPendingTurn = tryPickTile(_gameState, col, row);
    if (nextPendingTurn == null) return;

    // Show the just-selected tile immediately before deciding whether the turn
    // is complete and should animate.
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
    _scheduleCenterCapture();

    if (nextPendingTurn.picks.length == kGameColors.length) {
      // Wait one short frame so the third selected tile visually lands in the
      // selected state before the overlay stack takes over.
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      await _animateCompletedTurn(nextPendingTurn);
    }
  }

  Widget _buildGoalValue(String color) {
    final int value = _gameState.goal[color] ?? 0;
    if (value == 0) {
      return const Icon(Icons.check_rounded, size: 28, color: Colors.black);
    }
    if (value < 0) {
      return const Icon(Icons.close_rounded, size: 28, color: Colors.black);
    }
    return Text(
      '$value',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildGoalBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF16D86C), width: 5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(_goalOrder.length, (int index) {
          final String color = _goalOrder[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == _goalOrder.length - 1 ? 0 : 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  key: _goalSquareKeys[color],
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _colorForName(color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                _buildGoalValue(color),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _statusText() {
    switch (_gameState.status) {
      case GameStatus.won:
        return 'You Win';
      case GameStatus.lost:
        return 'You Lose';
      case GameStatus.playing:
        if (_gameState.requiredStartColor == null) {
          return 'Select any colour';
        }
        return 'Start with ${_gameState.requiredStartColor}';
    }
  }

  Widget _buildStatusText() {
    return Text(
      _statusText(),
      style: TextStyle(
        fontSize: 18,
        fontWeight: _gameState.status == GameStatus.playing
            ? FontWeight.w500
            : FontWeight.w700,
        color: _gameState.status == GameStatus.playing
            ? Colors.black54
            : Colors.black,
      ),
    );
  }

  Widget _buildGridTile({
    required int col,
    required int row,
    required String color,
    required double tileSize,
  }) {
    final String tileKey = _gridTileKey(col, row);
    final bool isHiddenForAnimation = _hiddenGridTileKeys.contains(tileKey);
    final TileVisualState visualState = getTileVisualState(
      _gameState,
      col,
      row,
      color,
    );
    final bool isInteractive =
        visualState == TileVisualState.bright && !_isAnimatingTurn;
    final bool isSelected = visualState == TileVisualState.selected;
    final double opacity = isHiddenForAnimation
        ? 0
        : visualState == TileVisualState.dulled
        ? 0.32
        : 1.0;

    return GestureDetector(
      onTap: isInteractive ? () => _onTileTap(col, row) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: isSelected ? _selectedTileScale : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: opacity,
          child: Container(
            key: _gridTileKeys[tileKey],
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: _colorForName(color),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid() {
    final int columnCount = _gameState.board.length;
    final int maxRows = _gameState.board.fold<int>(
      0,
      (int maxValue, List<String> column) => math.max(maxValue, column.length),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double horizontalGap = 32;
        const double verticalGap = 32;
        const double minTileSize = 34;
        const double maxTileSize = 56;

        final double widthLimited =
            (constraints.maxWidth -
                (horizontalGap * math.max(columnCount - 1, 0))) /
            math.max(columnCount, 1);
        final double heightLimited =
            (constraints.maxHeight - (verticalGap * math.max(maxRows - 1, 0))) /
            math.max(maxRows, 1);

        final double tileSize = math.max(
          minTileSize,
          math.min(maxTileSize, math.min(widthLimited, heightLimited)),
        );
        _lastTileSize = tileSize;

        final double boardWidth =
            (columnCount * tileSize) +
            (horizontalGap * math.max(columnCount - 1, 0));
        final double boardHeight =
            (maxRows * tileSize) + (verticalGap * math.max(maxRows - 1, 0));

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int col = 0; col < _gameState.board.length; col += 1)
                  for (
                    int row = 0;
                    row < _gameState.board[col].length;
                    row += 1
                  )
                    Positioned(
                      left: col * (tileSize + horizontalGap),
                      top:
                          boardHeight -
                          tileSize -
                          (row * (tileSize + verticalGap)),
                      child: _buildGridTile(
                        col: col,
                        row: row,
                        color: _gameState.board[col][row],
                        tileSize: tileSize,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Paints the flying stack overlay in screen coordinates.
  ///
  /// The whole overlay is above the board so it can move freely from the picked
  /// tile positions to the goal bar without being clipped by the grid area.
  Widget _buildTurnAnimationOverlay() {
    if (!_isAnimatingTurn || _animatedTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final CurvedAnimation curved = CurvedAnimation(
      parent: _stackFlightController,
      curve: Curves.easeInOutCubic,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: curved,
          builder: (BuildContext context, Widget? child) {
            final double t = curved.value;
            const double gatherEnd = 0.55;
            final double gatherT = math.min(t / gatherEnd, 1.0);
            final double flyT = t <= gatherEnd
                ? 0.0
                : (t - gatherEnd) / (1.0 - gatherEnd);
            final double animatedTileSize = _lastTileSize * _selectedTileScale;

            final String winnerColor = _animatedTiles.first.color;
            final Offset goalCenter = _goalSquareCenters[winnerColor]!;
            final double stackPeek = animatedTileSize * 0.32;

            return Stack(
              children: [
                for (final _AnimatedStackTile tile in _animatedTiles.reversed)
                  Builder(
                    builder: (BuildContext context) {
                      // Gather phase:
                      // - winner stays in place
                      // - other tiles move directly to stacked positions below it
                      final Offset gatheredCenter =
                          Offset.lerp(
                            tile.startCenter,
                            tile.stackCenter,
                            tile.stackOrder == 0 ? 0 : gatherT,
                          ) ??
                          tile.stackCenter;

                      // Fly phase:
                      // - the winner flies to the goal chip center
                      // - lower tiles keep their partial reveal offsets while
                      //   travelling with the same stack
                      final Offset destinationCenter = Offset(
                        goalCenter.dx,
                        goalCenter.dy + (stackPeek * tile.stackOrder),
                      );

                      final Offset animatedCenter =
                          Offset.lerp(
                            gatheredCenter,
                            destinationCenter,
                            flyT,
                          ) ??
                          destinationCenter;

                      return Positioned(
                        left: animatedCenter.dx - (animatedTileSize / 2),
                        top: animatedCenter.dy - (animatedTileSize / 2),
                        child: Container(
                          width: animatedTileSize,
                          height: animatedTileSize,
                          decoration: BoxDecoration(
                            color: _colorForName(tile.color),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  Center(child: _buildGoalBar()),
                  const SizedBox(height: 22),
                  _buildStatusText(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 92),
                      child: _buildResponsiveGrid(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildTurnAnimationOverlay(),
        ],
      ),
    );
  }
}

/// Frozen per-tile data for one resolved turn animation.
///
/// We keep this separate from [PickedTile] because animation needs explicit
/// start and destination centers measured from the actual rendered widgets.
class _AnimatedStackTile {
  const _AnimatedStackTile({
    required this.key,
    required this.color,
    required this.startCenter,
    required this.stackCenter,
    required this.stackOrder,
  });

  final String key;
  final String color;
  final Offset startCenter;
  final Offset stackCenter;
  final int stackOrder;
}
