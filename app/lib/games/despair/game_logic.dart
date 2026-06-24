// Core Despair game rules and turn-resolution helpers.
//
// This file intentionally contains only rule logic and lightweight game-state
// models. Keeping it separate from the widget tree makes the rules easier to
// reason about, test, and reuse from animated UI code.

enum TileVisualState { bright, selected, dulled }

enum GameStatus { playing, won, lost }

/// One concrete tile chosen by the player on the current turn.
///
/// [col] is the board column index.
/// [row] is the row index inside that column, where 0 is the bottom tile
/// because each column list is stored bottom -> top.
class PickedTile {
  const PickedTile({required this.col, required this.row, required this.color});

  final int col;
  final int row;
  final String color;

  String get key => '$col-$row';
}

/// In-progress turn state.
///
/// [primaryCol] is locked by the first tile the player selects for that turn.
/// The winner is always resolved from the topmost matching color in this
/// primary column.
class PendingTurn {
  const PendingTurn({required this.primaryCol, required this.picks});

  final int? primaryCol;
  final List<PickedTile> picks;

  static const PendingTurn empty = PendingTurn(
    primaryCol: null,
    picks: <PickedTile>[],
  );
}

/// Full UI-facing game snapshot.
///
/// The widget layer reads this to decide:
/// - which tiles are clickable
/// - which tiles should be dulled
/// - which color must start the next round
/// - whether the game has been won or lost
class GameViewState {
  const GameViewState({
    required this.board,
    required this.goal,
    required this.pendingTurn,
    required this.requiredStartColor,
    required this.status,
    required this.winnerColor,
  });

  final List<List<String>> board;
  final Map<String, int> goal;
  final PendingTurn pendingTurn;
  final String? requiredStartColor;
  final GameStatus status;
  final String? winnerColor;
}

/// Result of resolving one completed 3-color turn.
class TurnResult {
  const TurnResult({
    required this.board,
    required this.goal,
    required this.requiredStartColor,
    required this.status,
    required this.winnerColor,
  });

  final List<List<String>> board;
  final Map<String, int> goal;
  final String? requiredStartColor;
  final GameStatus status;
  final String winnerColor;
}

/// Fixed game color order used everywhere in the current UI and rule system.
const List<String> kGameColors = <String>['red', 'blue', 'yellow'];

List<List<String>> cloneBoard(List<List<String>> board) {
  return board.map((List<String> column) => List<String>.from(column)).toList();
}

Map<String, int> cloneGoal(Map<String, int> goal) {
  return <String, int>{
    for (final MapEntry<String, int> entry in goal.entries)
      entry.key: entry.value,
  };
}

bool colorExistsAnywhere(List<List<String>> board, String color) {
  return board.any((List<String> column) => column.contains(color));
}

bool colorExistsInColumn(List<List<String>> board, int col, String color) {
  if (col < 0 || col >= board.length) return false;
  return board[col].contains(color);
}

/// The target is reached only when every goal count is exactly zero.
bool goalsMatchedExactly(Map<String, int> goal) {
  return kGameColors.every((String color) => (goal[color] ?? 0) == 0);
}

/// Determines whether the current board still has at least one legal turn.
///
/// Rules enforced here:
/// - if [requiredStartColor] is set, the next turn must start with that color
/// - the first pick defines the primary column
/// - for each later color, if that color exists in the primary column the
///   player must pick it there
/// - if that color does not exist in the primary column, it may be picked from
///   any other column
bool hasAnyLegalTurn(List<List<String>> board, String? requiredStartColor) {
  final Iterable<String> allowedStartColors = requiredStartColor == null
      ? kGameColors
      : <String>[requiredStartColor];

  for (int primaryCol = 0; primaryCol < board.length; primaryCol += 1) {
    final List<String> column = board[primaryCol];
    for (final String startColor in allowedStartColors) {
      if (!column.contains(startColor)) continue;

      bool valid = true;
      for (final String color in kGameColors) {
        if (color == startColor) continue;
        if (column.contains(color)) continue;
        if (!colorExistsAnywhere(board, color)) {
          valid = false;
          break;
        }
      }
      if (valid) return true;
    }
  }

  return false;
}

/// Returns how a tile should look right now.
///
/// `bright`:
///   player is allowed to tap the tile now.
/// `selected`:
///   tile is part of the current turn and should visually grow a little.
/// `dulled`:
///   tile stays visible but is not currently legal to tap.
TileVisualState getTileVisualState(
  GameViewState state,
  int col,
  int row,
  String color,
) {
  if (state.status != GameStatus.playing) {
    return TileVisualState.dulled;
  }

  final PendingTurn pendingTurn = state.pendingTurn;
  final bool isSelected = pendingTurn.picks.any(
    (PickedTile tile) => tile.col == col && tile.row == row,
  );
  if (isSelected) {
    return TileVisualState.selected;
  }

  // Once a color has been picked this turn, every other tile of that same color
  // must dull immediately because a turn can contain each color only once.
  final Set<String> pickedColors = pendingTurn.picks
      .map((PickedTile tile) => tile.color)
      .toSet();
  if (pickedColors.contains(color)) {
    return TileVisualState.dulled;
  }

  // Before the first pick, either any color is allowed or the previous turn's
  // winner is forced as the starting color.
  if (pendingTurn.primaryCol == null) {
    if (state.requiredStartColor != null && color != state.requiredStartColor) {
      return TileVisualState.dulled;
    }
    return TileVisualState.bright;
  }

  // After the first pick, if the needed color exists in the primary column then
  // the player must pick that color there.
  if (colorExistsInColumn(state.board, pendingTurn.primaryCol!, color)) {
    return col == pendingTurn.primaryCol
        ? TileVisualState.bright
        : TileVisualState.dulled;
  }

  // If the primary column does not contain that needed color, any remaining
  // copy of that color anywhere on the board is legal.
  return TileVisualState.bright;
}

/// Attempts to add one tile to the current turn.
///
/// Returns `null` when the tap is illegal or the tile does not exist anymore.
PendingTurn? tryPickTile(GameViewState state, int col, int row) {
  if (col < 0 || col >= state.board.length) return null;
  if (row < 0 || row >= state.board[col].length) return null;

  final String color = state.board[col][row];
  if (getTileVisualState(state, col, row, color) != TileVisualState.bright) {
    return null;
  }

  final PendingTurn pendingTurn = state.pendingTurn;
  return PendingTurn(
    primaryCol: pendingTurn.primaryCol ?? col,
    picks: <PickedTile>[
      ...pendingTurn.picks,
      PickedTile(col: col, row: row, color: color),
    ],
  );
}

/// Resolves the turn winner from the primary column only.
///
/// We walk from top -> bottom inside the primary column and return the first
/// picked color we encounter. That is the "topmost picked color in the primary
/// column" rule the user specified.
String resolveWinnerColor(List<List<String>> board, PendingTurn pendingTurn) {
  final int primaryCol = pendingTurn.primaryCol!;
  final List<String> primaryColumn = board[primaryCol];
  final Set<String> pickedColors = pendingTurn.picks
      .map((PickedTile tile) => tile.color)
      .toSet();

  for (int row = primaryColumn.length - 1; row >= 0; row -= 1) {
    final String color = primaryColumn[row];
    if (pickedColors.contains(color)) {
      return color;
    }
  }

  throw StateError(
    'Could not resolve winner color for primary column $primaryCol',
  );
}

/// Applies one completed 3-color turn to the game state.
///
/// Steps:
/// 1. resolve the winning color from the primary column
/// 2. subtract 1 from that goal color
/// 3. remove all 3 picked tiles from the board
/// 4. determine whether the game is now won, lost, or still playable
/// 5. if still playable, force the next turn to start with the winner color
TurnResult resolveTurn(GameViewState state) {
  final PendingTurn pendingTurn = state.pendingTurn;
  final String winnerColor = resolveWinnerColor(state.board, pendingTurn);
  final Map<String, int> nextGoal = cloneGoal(state.goal);
  nextGoal[winnerColor] = (nextGoal[winnerColor] ?? 0) - 1;

  final List<List<String>> nextBoard = cloneBoard(state.board);

  // Remove picked tiles column by column from top -> bottom so row indices stay
  // valid even when multiple picked tiles come from the same column.
  final Map<int, List<PickedTile>> picksByColumn = <int, List<PickedTile>>{};
  for (final PickedTile tile in pendingTurn.picks) {
    picksByColumn.putIfAbsent(tile.col, () => <PickedTile>[]).add(tile);
  }
  for (final MapEntry<int, List<PickedTile>> entry in picksByColumn.entries) {
    final List<PickedTile> columnPicks = List<PickedTile>.from(entry.value)
      ..sort((PickedTile a, PickedTile b) => b.row.compareTo(a.row));
    for (final PickedTile tile in columnPicks) {
      nextBoard[tile.col].removeAt(tile.row);
    }
  }

  final GameStatus nextStatus;
  if (goalsMatchedExactly(nextGoal)) {
    nextStatus = GameStatus.won;
  } else if (!hasAnyLegalTurn(nextBoard, winnerColor)) {
    nextStatus = GameStatus.lost;
  } else {
    nextStatus = GameStatus.playing;
  }

  return TurnResult(
    board: nextBoard,
    goal: nextGoal,
    requiredStartColor: winnerColor,
    status: nextStatus,
    winnerColor: winnerColor,
  );
}
