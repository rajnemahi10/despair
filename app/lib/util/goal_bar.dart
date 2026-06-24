import 'package:flutter/material.dart';

/// Displays the three coloured goal chips and their remaining counts.
///
/// Each chip shows a coloured square next to a number. When the count reaches
/// zero the number is replaced with a check icon; when it goes negative (lost)
/// it shows a close icon.
class GoalBar extends StatelessWidget {
  const GoalBar({super.key, required this.goal, required this.goalKeys});

  final Map<String, int> goal;

  final Map<String, GlobalKey> goalKeys;

  static const List<String> _goalOrder = <String>['red', 'blue', 'yellow'];

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

  Widget _buildGoalValue(String color) {
    final int value = goal[color] ?? 0;
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

  @override
  Widget build(BuildContext context) {
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
                  key: goalKeys[color],
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
}
