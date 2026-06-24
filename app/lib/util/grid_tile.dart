import 'package:app/games/despair/game_logic.dart';
import 'package:flutter/material.dart';

/// Single coloured tile on the game board.
///
/// Handles its own scale and opacity animations based on [visualState].
/// Tapping a bright tile calls [onTap]; dulled and selected tiles are
/// non-interactive.
class GridTile extends StatelessWidget {
  const GridTile({
    super.key,
    required this.color,
    required this.tileSize,
    required this.visualState,
    required this.onTap,
  });

  static const double selectedTileScale = 1.14;

  final String color;
  final double tileSize;
  final TileVisualState visualState;

  /// Called when the tile is tapped. Null when the tile is not interactive.
  final VoidCallback? onTap;

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

  @override
  Widget build(BuildContext context) {
    final bool isSelected = visualState == TileVisualState.selected;
    final double opacity = visualState == TileVisualState.dulled ? 0.32 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: isSelected ? selectedTileScale : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: opacity,
          child: Container(
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
}
