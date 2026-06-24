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
    this.trumpCol,
  });

  final List<List<String>> board;
  final Map<String, int> goal;
  final int no;
  final int id;
  final bool hasHint;
  final bool isTut;

  /// Optional 1-based trump column coming from the level data.
  final int? trumpCol;

  @override
  State<LevelPageFormat> createState() => _LevelPageFormatState();
}

class _LevelPageFormatState extends State<LevelPageFormat>
    with TickerProviderStateMixin {
  /// The three tile ids currently participating in the turn animation.
  ///
  /// We keep these ids so [ResponsiveGrid] knows which exact board tiles
  /// should receive translation offsets during the stack / fly sequence.
  Set<String> animatingTiles = {};

  /// Per-tile translation offsets used by [ResponsiveGrid].
  ///
  /// These are relative movement deltas from each tile's original board slot:
  /// - [topOffset] stays zero during stack formation because the winner tile
  ///   remains pinned in place.
  /// - [midOffset] and [bottomOffset] animate the lower two tiles upward into
  ///   a stack, then all three offsets animate toward the winning goal chip.
  Offset topOffset = Offset.zero;
  Offset midOffset = Offset.zero;
  Offset bottomOffset = Offset.zero;

  /// The animation is now split into three explicit phases.
  ///
  /// This is easier for a beginner to follow than one long controller with
  /// intervals:
  /// 1. middle tile stacks under the winner
  /// 2. bottom tile stacks under the middle tile
  /// 3. each tile in the finished stack flies to the goal bar
  late final AnimationController _middleStackController;
  late final AnimationController _bottomStackController;
  late final AnimationController _topFlyController;
  late final AnimationController _midFlyController;
  late final AnimationController _bottomFlyController;

  late Animation<Offset> _middleStackTween;
  late Animation<Offset> _bottomStackTween;
  late Animation<Offset> _topFlyTween;
  late Animation<Offset> _midFlyTween;
  late Animation<Offset> _bottomFlyTween;

  String? topAnimatingId;
  String? midAnimatingId;
  String? bottomAnimatingId;

  /// We temporarily store the completed turn here while its animation plays.
  ///
  /// The board should not be mutated immediately after the 3rd pick, otherwise
  /// the tiles would disappear before the player sees the stack and fly motion.
  PendingTurn? _resolvingTurn;

  /// Returns the on-screen centre point of a widget identified by [key].
  ///
  /// The animation math uses widget centres rather than top-left corners
  /// because centre-to-centre movement is easier to reason about.
  Offset getPosition(GlobalKey key) {
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    final Size size = box.size;
    return box.localToGlobal(Offset(size.width / 2, size.height / 2));
  }

  final Map<String, GlobalKey> goalKeys = {
    'red': GlobalKey(),
    'blue': GlobalKey(),
    'yellow': GlobalKey(),
  };

  /// Stable helper for producing a unique tile id from its board location.
  ///
  /// The same string format is reused by:
  /// - the tile key map
  /// - the selected / animating tile sets
  /// - the grid when it decides which widgets should move
  String tileId(int col, int row) => '$col-$row';

  /// Each visible board tile gets a [GlobalKey] so we can measure where it is
  /// on screen right before animation starts.
  final Map<String, GlobalKey> tileKeys = {};

  late GameViewState _gameState;
  bool _isResolvingTurn = false;
  int _completedFlyAnimations = 0;
  bool _isMiddleStackPhaseActive = false;
  bool _isBottomStackPhaseActive = false;
  bool _isFlyPhaseActive = false;

  void _clearAnimationState() {
    animatingTiles = {};
    topAnimatingId = null;
    midAnimatingId = null;
    bottomAnimatingId = null;
    topOffset = Offset.zero;
    midOffset = Offset.zero;
    bottomOffset = Offset.zero;
    _isMiddleStackPhaseActive = false;
    _isBottomStackPhaseActive = false;
    _isFlyPhaseActive = false;
  }

  @override
  void initState() {
    super.initState();

    // Pre-build keys for every initial tile position. Later, when tiles are
    // removed after a turn, the rebuilt board will reuse the remaining keys
    // only for tiles that still exist in those positions.
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

    _middleStackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _bottomStackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _topFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _midFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bottomFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Phase 1: only the middle tile moves.
    _middleStackController.addListener(() {
      if (!_isMiddleStackPhaseActive) return;
      setState(() {
        midOffset = _middleStackTween.value;
      });
    });

    // When the middle tile has finished stacking, start the bottom-tile stack.
    _middleStackController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _isMiddleStackPhaseActive = false;
        _isBottomStackPhaseActive = true;
        _bottomStackController.forward(from: 0);
      }
    });

    // Phase 2: the bottom tile moves after the middle tile has already reached
    // its stacked location.
    _bottomStackController.addListener(() {
      if (!_isBottomStackPhaseActive) return;
      setState(() {
        bottomOffset = _bottomStackTween.value;
      });
    });

    // Once the full three-tile stack exists, begin the upward flight.
    _bottomStackController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _isBottomStackPhaseActive = false;
        _isFlyPhaseActive = true;
        _completedFlyAnimations = 0;
        _topFlyController.forward(from: 0);
        _midFlyController.forward(from: 0);
        _bottomFlyController.forward(from: 0);
      }
    });

    // Phase 3a: the winner tile flies to the goal.
    _topFlyController.addListener(() {
      if (!_isFlyPhaseActive) return;
      setState(() {
        topOffset = _topFlyTween.value;
      });
    });

    // Phase 3b: the middle tile flies while preserving its stacked spacing.
    _midFlyController.addListener(() {
      if (!_isFlyPhaseActive) return;
      setState(() {
        midOffset = _midFlyTween.value;
      });
    });

    // Phase 3c: the bottom tile flies while preserving its stacked spacing.
    _bottomFlyController.addListener(() {
      if (!_isFlyPhaseActive) return;
      setState(() {
        bottomOffset = _bottomFlyTween.value;
      });
    });

    void handleFlyCompleted(AnimationStatus status) {
      if (status != AnimationStatus.completed || _resolvingTurn == null) {
        return;
      }

      _completedFlyAnimations += 1;
      if (_completedFlyAnimations == 3) {
        _isFlyPhaseActive = false;
        final PendingTurn completedTurn = _resolvingTurn!;
        _resolvingTurn = null;
        _clearAnimationState();
        _applyResolvedTurn(completedTurn);
      }
    }

    _topFlyController.addStatusListener(handleFlyCompleted);
    _midFlyController.addStatusListener(handleFlyCompleted);
    _bottomFlyController.addStatusListener(handleFlyCompleted);
  }

  @override
  void dispose() {
    _middleStackController.dispose();
    _bottomStackController.dispose();
    _topFlyController.dispose();
    _midFlyController.dispose();
    _bottomFlyController.dispose();
    super.dispose();
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
      trumpCol: widget.trumpCol,
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

  /// Handles a player's tap on one board tile.
  ///
  /// High-level flow:
  /// 1. ask the rule engine whether this tap is legal
  /// 2. update temporary selection state
  /// 3. if this was the 3rd pick, build the stack/fly animation
  /// 4. once animation completes, actually remove the tiles and update score
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
      // At the moment the 3rd color is picked we freeze this exact turn so the
      // board can stay visually stable while the animation runs. The turn is
      // applied only after the controller finishes.
      //
      // Important rule:
      // The tile at the top of the animated stack is NOT "the first tile the
      // user tapped". It must always be the actual winning tile resolved from
      // the active column.
      final List<PickedTile> picks = nextPendingTurn.picks;
      _resolvingTurn = nextPendingTurn;

      final PickedTile topAnimatingTile = resolveWinningTile(
        _gameState.board,
        nextPendingTurn,
        trumpCol: widget.trumpCol,
      );
      final String winnerColor = topAnimatingTile.color;

      // The remaining two picked tiles always stack under the winner in the
      // same order the player selected them.
      //
      // That rule is especially important when a trump-column tile wins from a
      // different column: the winner must still stay on top, and the other two
      // tiles should preserve the player's pick sequence underneath it.
      final List<PickedTile> lowerStackTiles = picks
          .where((PickedTile tile) => tile.key != topAnimatingTile.key)
          .toList();

      topAnimatingId = tileId(topAnimatingTile.col, topAnimatingTile.row);

      midAnimatingId = tileId(lowerStackTiles[0].col, lowerStackTiles[0].row);

      bottomAnimatingId = tileId(
        lowerStackTiles[1].col,
        lowerStackTiles[1].row,
      );

      animatingTiles = {topAnimatingId!, midAnimatingId!, bottomAnimatingId!};

      final GlobalKey topKey =
          tileKeys[tileId(topAnimatingTile.col, topAnimatingTile.row)]!;

      final GlobalKey midKey =
          tileKeys[tileId(lowerStackTiles[0].col, lowerStackTiles[0].row)]!;

      final GlobalKey bottomKey =
          tileKeys[tileId(lowerStackTiles[1].col, lowerStackTiles[1].row)]!;

      final Offset topPos = getPosition(topKey);
      final Offset midPos = getPosition(midKey);
      final Offset bottomPos = getPosition(bottomKey);

      final GlobalKey goalKey = goalKeys[winnerColor]!;
      final Offset goalPos = getPosition(goalKey);

      // Fixed overlap spacing for the current stack prototype.
      //
      // This says "the middle tile should peek out 18 px under the top tile,
      // and the bottom tile should peek out another 18 px under the middle."
      const double stackPeek = 18;
      final Offset topTarget = topPos;
      final Offset middleTarget = Offset(topPos.dx, topPos.dy + stackPeek);
      final Offset bottomTarget = Offset(
        topPos.dx,
        topPos.dy + (stackPeek * 2),
      );

      // Fly targets must preserve the exact stack shape at the goal.
      //
      // So:
      // - the winner flies to the goal chip centre
      // - the middle tile flies to 18 px below that centre
      // - the bottom tile flies to 36 px below that centre
      final Offset goalTopTarget = goalPos;
      final Offset goalMiddleTarget = Offset(
        goalPos.dx,
        goalPos.dy + stackPeek,
      );
      final Offset goalBottomTarget = Offset(
        goalPos.dx,
        goalPos.dy + (stackPeek * 2),
      );

      final Offset topFlyDelta = Offset(
        goalTopTarget.dx - topTarget.dx,
        goalTopTarget.dy - topTarget.dy,
      );

      // These fly deltas are measured from the tiles' stacked positions, not
      // from their original board positions. That is what keeps the stack shape
      // intact while it travels to the goal bar.
      final Offset middleFlyDelta = Offset(
        goalMiddleTarget.dx - middleTarget.dx,
        goalMiddleTarget.dy - middleTarget.dy,
      );

      final Offset bottomFlyDelta = Offset(
        goalBottomTarget.dx - bottomTarget.dx,
        goalBottomTarget.dy - bottomTarget.dy,
      );

      // During the first phase, the middle tile moves from its own position to
      // just below the top tile.
      final Offset middleDelta = Offset(
        middleTarget.dx - midPos.dx,
        middleTarget.dy - midPos.dy,
      );

      // During the first phase, the bottom tile moves from its own position to
      // just below the middle tile.
      final Offset bottomDelta = Offset(
        bottomTarget.dx - bottomPos.dx,
        bottomTarget.dy - bottomPos.dy,
      );

      // Build the tweens for the three separate animation phases.
      //
      // Because each phase has its own controller, we no longer need Intervals
      // to chop up one big timeline.
      _middleStackTween = Tween<Offset>(
        begin: Offset.zero,
        end: middleDelta,
      ).animate(
        CurvedAnimation(
          parent: _middleStackController,
          curve: Curves.easeInOut,
        ),
      );

      _bottomStackTween = Tween<Offset>(
        begin: Offset.zero,
        end: bottomDelta,
      ).animate(
        CurvedAnimation(
          parent: _bottomStackController,
          curve: Curves.easeInOut,
        ),
      );

      // Because the top tile never moved during the stack phases, its fly tween
      // starts from zero offset.
      _topFlyTween = Tween<Offset>(begin: Offset.zero, end: topFlyDelta)
          .animate(
            CurvedAnimation(
              parent: _topFlyController,
              curve: Curves.easeInOut,
            ),
          );

      // The middle tile begins the fly phase from its already-finished stacked
      // offset instead of from zero.
      _midFlyTween =
          Tween<Offset>(
            begin: middleDelta,
            end: middleDelta + middleFlyDelta,
          ).animate(
            CurvedAnimation(
              parent: _midFlyController,
              curve: Curves.easeInOut,
            ),
          );

      // Same idea for the bottom tile.
      _bottomFlyTween =
          Tween<Offset>(
            begin: bottomDelta,
            end: bottomDelta + bottomFlyDelta,
          ).animate(
            CurvedAnimation(
              parent: _bottomFlyController,
              curve: Curves.easeInOut,
            ),
          );

      setState(() {
        topOffset = Offset.zero;
        midOffset = Offset.zero;
        bottomOffset = Offset.zero;
        _isResolvingTurn = true;
      });

      // Reset every controller so the phase chain always starts cleanly.
      _isMiddleStackPhaseActive = false;
      _isBottomStackPhaseActive = false;
      _isFlyPhaseActive = false;
      _middleStackController.reset();
      _bottomStackController.reset();
      _topFlyController.reset();
      _midFlyController.reset();
      _bottomFlyController.reset();

      // Kick off only the first phase. The later phases begin from their
      // status listeners when the previous controller reports completion.
      _isMiddleStackPhaseActive = true;
      _middleStackController.forward(from: 0);
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
                builder: (BuildContext context) => RulesTile(
                  hasTrumpColumn: widget.trumpCol != null,
                ),
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
                    trumpCol: widget.trumpCol,
                    onTileTap: _onTileTap,
                    tileKeys: tileKeys,
                    animatingTiles: animatingTiles,
                    topOffset: topOffset,
                    midOffset: midOffset,
                    bottomOffset: bottomOffset,
                    topAnimatingId: topAnimatingId,
                    midAnimatingId: midAnimatingId,
                    bottomAnimatingId: bottomAnimatingId,
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
