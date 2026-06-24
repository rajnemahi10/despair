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

  @override
  Widget build(BuildContext context) {
    final int columnCount = gameState.board.length;
    final int maxRows = gameState.board.fold<int>(
      0,
      (int maxValue, List<String> column) => math.max(maxValue, column.length),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int col = 0; col < gameState.board.length; col += 1)
                  for (int row = 0; row < gameState.board[col].length; row += 1)
                    Positioned(
                      left: col * (tileSize + _horizontalGap),
                      top:
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
