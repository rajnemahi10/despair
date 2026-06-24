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
/// That column stays active for the turn, but a trump column may override the
/// winner when a missing active-column color is picked from the trump column.
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
///
/// Keeping one shared order prevents subtle bugs such as:
/// - the UI showing colors in one order
/// - the rules checking a different order
/// - the goal bar expecting a third order
const List<String> kGameColors = <String>['red', 'blue', 'yellow'];

/// Creates a deep-enough copy of the board for gameplay updates.
///
/// Each column is copied into a new list so removing tiles from the next board
/// does not mutate the original board that widgets may still be reading.
List<List<String>> cloneBoard(List<List<String>> board) {
  return board.map((List<String> column) => List<String>.from(column)).toList();
}

/// Copies the current goal map before score changes are applied.
Map<String, int> cloneGoal(Map<String, int> goal) {
  return <String, int>{
    for (final MapEntry<String, int> entry in goal.entries)
      entry.key: entry.value,
  };
}

/// Returns true if at least one copy of [color] exists anywhere on the board.
bool colorExistsAnywhere(List<List<String>> board, String color) {
  return board.any((List<String> column) => column.contains(color));
}

/// Returns true if [color] exists in a specific column.
///
/// The bounds check is kept here so callers can stay simple and do not have to
/// repeatedly guard the index before asking this question.
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

  // We simulate only the *existence* of a valid turn here.
  //
  // We are not building the actual turn step by step. We are just checking:
  // "Is there any possible starting column + starting color combination that
  // could still legally collect all 3 colors?"
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
    // The first legal pick locks the active column for the rest of the turn.
    primaryCol: pendingTurn.primaryCol ?? col,
    picks: <PickedTile>[
      ...pendingTurn.picks,
      PickedTile(col: col, row: row, color: color),
    ],
  );
}

/// Convenience helper used when callers only need the winner's color.
String resolveWinnerColor(
  List<List<String>> board,
  PendingTurn pendingTurn, {
  int? trumpCol,
}) {
  return resolveWinningTile(board, pendingTurn, trumpCol: trumpCol).color;
}

/// Resolves the exact tile that wins the completed turn.
///
/// Why this helper matters:
/// - the scoring logic only needs the winner color
/// - the animation logic needs the exact tile location that stays pinned on
///   top while the other two tiles stack underneath it
///
/// Trump rule enforced here:
/// - the first pick still defines the active column
/// - if a picked color is missing from the active column *and* that picked
///   tile came from the trump column, then the trump column overrides the
///   active column for winner resolution
/// - when trump overrides, the topmost picked tile in the trump column wins
PickedTile resolveWinningTile(
  List<List<String>> board,
  PendingTurn pendingTurn, {
  int? trumpCol,
}) {
  final int primaryCol = pendingTurn.primaryCol!;
  // Level data stores trump as 1-based because that is friendlier for humans.
  // The board lists use 0-based indexes because that is what Dart lists use.
  final int? trumpIndex = trumpCol == null ? null : trumpCol - 1;
  final Set<String> pickedColors = pendingTurn.picks
      .map((PickedTile tile) => tile.color)
      .toSet();

  bool useTrumpWinner = false;
  if (trumpIndex != null &&
      trumpIndex >= 0 &&
      trumpIndex < board.length &&
      trumpIndex != primaryCol) {
    for (final PickedTile tile in pendingTurn.picks) {
      final bool missingFromPrimary = !colorExistsInColumn(
        board,
        primaryCol,
        tile.color,
      );
      // Trump only activates when both conditions are true:
      // 1. that color does not exist in the active column
      // 2. the player chose that missing color from the trump column
      if (missingFromPrimary && tile.col == trumpIndex) {
        useTrumpWinner = true;
        break;
      }
    }
  }

  final int winnerColumn = useTrumpWinner ? trumpIndex! : primaryCol;
  final List<String> winnerColumnTiles = board[winnerColumn];

  // Walk from top -> bottom because the topmost picked tile in the winner
  // column is the one that wins the set.
  for (int row = winnerColumnTiles.length - 1; row >= 0; row -= 1) {
    final String color = winnerColumnTiles[row];
    if (!pickedColors.contains(color)) continue;

    // We return the exact PickedTile object so the animation layer knows the
    // winner's real board coordinates, not just its color.
    for (final PickedTile tile in pendingTurn.picks) {
      if (tile.col == winnerColumn && tile.row == row && tile.color == color) {
        return tile;
      }
    }
  }

  throw StateError(
    'Could not resolve winning tile for primary column $primaryCol and trump column $trumpCol',
  );
}

/// Applies one completed 3-color turn to the game state.
///
/// Steps:
/// 1. resolve the winning color from the active column or trump column
/// 2. subtract 1 from that goal color
/// 3. remove all 3 picked tiles from the board
/// 4. determine whether the game is now won, lost, or still playable
/// 5. if still playable, force the next turn to start with the winner color
TurnResult resolveTurn(GameViewState state, {int? trumpCol}) {
  final PendingTurn pendingTurn = state.pendingTurn;
  final String winnerColor = resolveWinnerColor(
    state.board,
    pendingTurn,
    trumpCol: trumpCol,
  );
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
