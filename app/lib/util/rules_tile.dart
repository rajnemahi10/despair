import 'package:flutter/material.dart';

/// Dialog-style rules overlay for the Despair game.
///
/// This file is intentionally UI-only. The actual rule enforcement lives in
/// `games/despair/game_logic.dart`. The text below mirrors the current rule set
/// the player is expected to learn from the UI.
class RulesTile extends StatelessWidget {
  const RulesTile({super.key, required this.hasTrumpColumn});

  /// Decides whether the trump-specific rule should be shown in the popup.
  ///
  /// We keep this dynamic so early levels without trump stay simpler to learn.
  final bool hasTrumpColumn;

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
  /// 6. If that missing color is picked from the trump column, the trump column
  ///    can override the active column and its topmost picked tile wins.
  /// 7. In the animation, the winning tile always stays on top and the other
  ///    two selected tiles stack under it in selection order.
  /// 8. The winning color reduces its goal count by 1 and must start the next
  ///    turn if the game continues.
  List<String> get rules {
    // Start with the rules that every level shares.
    final List<String> baseRules = <String>[
      'Aim of the game is to reach the target exactly.',
      '3 colours make a set: one red, one blue, and one yellow.',
      'The first tile you pick decides the active column for that turn.',
      'If a needed colour exists in the active column, you must pick it there.',
      'If a needed colour does not exist in the active column, you may pick it from any other column.',
    ];

    if (hasTrumpColumn) {
      // Only trump levels need this extra explanation.
      baseRules.add(
        'If a missing active-column colour is picked from the trump column, the topmost picked colour in the trump column wins instead.',
      );
    }

    // End with the rules that always happen after a winner is decided.
    baseRules.addAll(<String>[
      'In the animation, the winning tile stays on top and the other two stack below it in the order you selected them.',
      'The winning colour reduces its goal count by 1 and starts the next turn.',
    ]);

    return baseRules;
  }

  @override
  Widget build(BuildContext context) {
    final double maxDialogHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Material(
      color: Colors.black.withAlpha(90),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 26),
              decoration: BoxDecoration(
                color: const Color(0xFF86858F),
                borderRadius: BorderRadius.circular(34),
              ),
              child: Column(
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
                  const SizedBox(height: 2),
                  const Text(
                    'Rules',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The rule list is the part most likely to overflow on
                  // shorter screens, so only that section becomes scrollable.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(rules.length, (
                          int index,
                        ) {
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
