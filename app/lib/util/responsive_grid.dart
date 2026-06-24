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
  });

  final GameViewState gameState;
  final bool isResolvingTurn;
  final Map<String, GlobalKey> tileKeys;

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

    return GridTile(
      key: tileKeys['$col-$row'],
      color: color,
      tileSize: tileSize,
      visualState: visualState,
      onTap: isInteractive ? () => onTileTap(col, row) : null,
    );
  }
}
