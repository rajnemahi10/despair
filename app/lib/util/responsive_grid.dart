import 'dart:math' as math;

import 'package:app/games/despair/game_logic.dart';
import 'package:app/util/grid_tile.dart';
import 'package:flutter/material.dart' hide GridTile;

/// Lays out the full tile board, sizing each tile to fill the available space.
///
/// Tiles are stacked bottom-up within each column: row 0 sits at the bottom,
/// higher rows sit above it. The board is centred inside whatever space is
/// given by the parent.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.gameState,
    required this.isResolvingTurn,
    required this.trumpCol,
    required this.onTileTap,
    required this.tileKeys,
    required this.animatingTiles,
    required this.topOffset,
    required this.midOffset,
    required this.bottomOffset,
    required this.topAnimatingId,
    required this.midAnimatingId,
    required this.bottomAnimatingId,
  });

  final GameViewState gameState;
  final bool isResolvingTurn;
  final int? trumpCol;
  final Map<String, GlobalKey> tileKeys;

  /// The three currently animating tile ids.
  ///
  /// These ids let the grid know which concrete board tiles should be wrapped
  /// in Transform.translate for the current manual stack animation.
  final Set<String> animatingTiles;

  /// Relative translation offsets for the selected top/middle/bottom tiles.
  ///
  /// These are *not* absolute coordinates. Each tile is still laid out in its
  /// normal grid slot first, and then moved relative to that slot.
  final Offset topOffset;
  final Offset midOffset;
  final Offset bottomOffset;

  final String? topAnimatingId;
  final String? midAnimatingId;
  final String? bottomAnimatingId;

  /// Called with (col, row) when the player taps an interactive tile.
  final void Function(int col, int row) onTileTap;

  static const double _horizontalGap = 32;
  static const double _verticalGap = 32;
  static const double _minTileSize = 34;
  static const double _maxTileSize = 56;

  /// Extra vertical room reserved above the board when a trump star is shown.
  static const double _trumpTopSpace = 34;

  /// Padding between the outer pink rim and the actual trump-column tiles.
  static const double _trumpRimPadding = 18;

  /// Padding between the active-column green rim and its tiles.
  ///
  /// This is slightly smaller than the trump padding so both borders can sit
  /// together when the active column and trump column are the same.
  static const double _activeRimPadding = 12;

  @override
  Widget build(BuildContext context) {
    final int columnCount = gameState.board.length;
    final int maxRows = gameState.board.fold<int>(
      0,
      (int maxValue, List<String> column) => math.max(maxValue, column.length),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The tile size is responsive:
        // - widthLimited says how big a tile can be before columns overflow
        // - heightLimited says how big a tile can be before rows overflow
        // - then we clamp that value between a small minimum and maximum size
        final double widthLimited =
            (constraints.maxWidth -
                (_horizontalGap * math.max(columnCount - 1, 0))) /
            math.max(columnCount, 1);
        final double heightLimited =
            (constraints.maxHeight -
                (_verticalGap * math.max(maxRows - 1, 0))) /
            math.max(maxRows, 1);

        final double tileSize = math.max(
          _minTileSize,
          math.min(_maxTileSize, math.min(widthLimited, heightLimited)),
        );

        final double boardWidth =
            (columnCount * tileSize) +
            (_horizontalGap * math.max(columnCount - 1, 0));
        final double boardHeight =
            (maxRows * tileSize) + (_verticalGap * math.max(maxRows - 1, 0));
        final bool hasTrumpColumn =
            trumpCol != null && trumpCol! >= 1 && trumpCol! <= columnCount;
        final int? activeColumn = gameState.pendingTurn.primaryCol;

        // If there is a trump column, leave space for the star above it so the
        // board itself can remain visually centred.
        final double topInset = hasTrumpColumn ? _trumpTopSpace : 0;

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight + topInset,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The trump highlight is drawn behind the actual tiles so the
                // player can immediately understand which column has the
                // special power. The pink rim hugs only the occupied height of
                // that column, not the full empty board area.
                if (hasTrumpColumn)
                  _buildTrumpDecoration(
                    tileSize: tileSize,
                    boardHeight: boardHeight,
                    trumpIndex: trumpCol! - 1,
                    topInset: topInset,
                  ),
                // The active column is decided by the first tile picked in the
                // current turn. Once it exists, we show a green rim around the
                // occupied height of that column.
                if (activeColumn != null)
                  _buildActiveColumnDecoration(
                    tileSize: tileSize,
                    boardHeight: boardHeight,
                    activeColumn: activeColumn,
                    topInset: topInset,
                  ),
                for (int col = 0; col < gameState.board.length; col += 1)
                  for (int row = 0; row < gameState.board[col].length; row += 1)
                    Positioned(
                      left: col * (tileSize + _horizontalGap),
                      top:
                          topInset +
                          boardHeight -
                          tileSize -
                          (row * (tileSize + _verticalGap)),
                      child: _buildTile(col, row, tileSize),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrumpDecoration({
    required double tileSize,
    required double boardHeight,
    required int trumpIndex,
    required double topInset,
  }) {
    // Only the occupied part of the trump column is highlighted.
    // This keeps the rim tight around the tiles instead of drawing a very tall
    // empty outline through unused board space.
    final int trumpRows = gameState.board[trumpIndex].length;
    final double columnHeight =
        (trumpRows * tileSize) + (_verticalGap * math.max(trumpRows - 1, 0));
    final double columnLeft = trumpIndex * (tileSize + _horizontalGap);
    final double columnTop = topInset + (boardHeight - columnHeight);
    final double rimLeft = columnLeft - _trumpRimPadding;
    final double rimTop = columnTop - _trumpRimPadding;
    final double rimWidth = tileSize + (_trumpRimPadding * 2);
    final double rimHeight = columnHeight + (_trumpRimPadding * 2);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Pink rounded border around the entire trump column.
        Positioned(
          left: rimLeft,
          top: rimTop,
          child: Container(
            width: rimWidth,
            height: rimHeight,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE94BB3), width: 6),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
        // Star badge above the trump column.
        Positioned(
          left: columnLeft + (tileSize / 2) - 18,
          top: rimTop - 26,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB400),
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  /// Draws the green rim around the current active column.
  ///
  /// This appears only after the first pick because that is when the game's
  /// "active column" rule becomes locked for the turn.
  Widget _buildActiveColumnDecoration({
    required double tileSize,
    required double boardHeight,
    required int activeColumn,
    required double topInset,
  }) {
    final int activeRows = gameState.board[activeColumn].length;
    final double columnHeight =
        (activeRows * tileSize) + (_verticalGap * math.max(activeRows - 1, 0));
    final double columnLeft = activeColumn * (tileSize + _horizontalGap);
    final double columnTop = topInset + (boardHeight - columnHeight);
    final double rimLeft = columnLeft - _activeRimPadding;
    final double rimTop = columnTop - _activeRimPadding;
    final double rimWidth = tileSize + (_activeRimPadding * 2);
    final double rimHeight = columnHeight + (_activeRimPadding * 2);

    return Positioned(
      left: rimLeft,
      top: rimTop,
      child: IgnorePointer(
        child: Container(
          width: rimWidth,
          height: rimHeight,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00A94F), width: 6),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int col, int row, double tileSize) {
    final String color = gameState.board[col][row];
    final TileVisualState visualState = getTileVisualState(
      gameState,
      col,
      row,
      color,
    );
    final bool isInteractive =
        visualState == TileVisualState.bright && !isResolvingTurn;

    Widget tile = GridTile(
      key: tileKeys['$col-$row'],
      color: color,
      tileSize: tileSize,
      visualState: visualState,
      onTap: isInteractive ? () => onTileTap(col, row) : null,
    );

    final String id = '$col-$row';
    // During the stack animation we keep using the same actual grid widgets,
    // but translate only the three selected ones. This keeps the code simple:
    // the board still owns the tiles, while LevelPageFormat only feeds in the
    // animation offsets.
    if (id == topAnimatingId) {
      return Transform.translate(offset: topOffset, child: tile);
    }

    if (id == midAnimatingId) {
      return Transform.translate(offset: midOffset, child: tile);
    }

    if (id == bottomAnimatingId) {
      return Transform.translate(offset: bottomOffset, child: tile);
    }

    return tile;
  }
}
