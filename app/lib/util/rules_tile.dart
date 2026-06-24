import 'package:flutter/material.dart';

/// Dialog-style rules overlay for the Despair game.
///
/// This file is intentionally UI-only. The actual rule enforcement lives in
/// `games/despair/game_logic.dart`. The text below mirrors the current rule set
/// the player is expected to learn from the UI.
class RulesTile extends StatelessWidget {
  const RulesTile({super.key});

  /// Human-readable rule summary shown to the player.
  ///
  /// Current rules represented here:
  /// 1. A turn starts with any color, unless the previous winning color forces
  ///    the next start.
  /// 2. The first selected tile defines the primary column for that turn.
  /// 3. A turn must contain one red, one blue, and one yellow.
  /// 4. If a needed color exists in the primary column, it must be picked there.
  /// 5. If a needed color does not exist in the primary column, it may be taken
  ///    from any other column.
  /// 6. The topmost picked color in the primary column wins the turn.
  /// 7. The winning color reduces its goal count by 1 and must start the next
  ///    turn if the game continues.
  static const List<String> rules = <String>[
    'Aim of the game is to reach the target exactly.',
    '3 colours make a set: one red, one blue, and one yellow.',
    'The first tile you pick decides the active column for that turn.',
    'If a needed colour exists in the active column, you must pick it there.',
    'If a needed colour does not exist in the active column, you may pick it from any other column.',
    'The topmost picked colour in the active column wins the point and starts the next turn.',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(90),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 30),
              decoration: BoxDecoration(
                color: const Color(0xFF86858F),
                borderRadius: BorderRadius.circular(34),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 36,
                      ),
                      splashRadius: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Rules',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ...List<Widget>.generate(rules.length, (int index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rules[index],
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
