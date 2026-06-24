import 'package:flutter/material.dart';
import 'package:app/games/despair/level_page.dart';
import 'package:app/util/level_tile.dart';
import 'package:app/util/settings_tile.dart';

/// Flutter version of one Despair level definition.
///
/// This mirrors the shape of the original web data:
/// - [board] is a list of columns
/// - each column is ordered bottom -> top
/// - [goal] stores the exact target counts for each color
/// - [isTutorial], [hasHint], and [trumpCol] are optional flags/metadata
class DespairLevelData {
  const DespairLevelData({
    required this.board,
    required this.goal,
    required this.id,
    this.hasHint = false,
    this.isTutorial = false,
    this.trumpCol,
  });

  final List<List<String>> board;
  final Map<String, int> goal;
  final int id;
  final bool hasHint;
  final bool isTutorial;
  /// Optional 1-based trump column for special levels.
  final int? trumpCol;
}

/// Full Despair level list, ported from the web version.
///
/// A beginner reading this file can think of each level like this:
/// - [board] = what tiles exist on screen at the start
/// - [goal] = how many points each color still needs
/// - [id] = level number shown in the UI
/// - [trumpCol] = optional special column with star + pink outline
const List<DespairLevelData> levels = <DespairLevelData>[
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'blue', 'red'],
    ],
    goal: <String, int>{'blue': 0, 'red': 1, 'yellow': 0},
    id: 1,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'yellow', 'blue'],
    ],
    goal: <String, int>{'blue': 1, 'red': 0, 'yellow': 0},
    hasHint: true,
    id: 2,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'yellow', 'blue', 'red', 'red', 'yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 1, 'yellow': 1},
    id: 3,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'yellow', 'blue', 'red', 'yellow', 'blue'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 0},
    hasHint: true,
    id: 4,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'blue', 'red'],
      <String>['red', 'blue', 'yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 1, 'yellow': 1},
    id: 5,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'yellow', 'blue', 'red', 'yellow'],
      <String>['blue', 'red', 'yellow'],
    ],
    goal: <String, int>{'blue': 1, 'red': 0, 'yellow': 2},
    id: 6,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'yellow', 'blue', 'yellow', 'red'],
      <String>['red', 'blue', 'yellow', 'blue', 'yellow', 'red'],
    ],
    goal: <String, int>{'blue': 1, 'red': 2, 'yellow': 1},
    id: 7,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'yellow', 'blue', 'red', 'yellow'],
      <String>['red', 'red', 'yellow', 'blue', 'yellow', 'blue'],
    ],
    goal: <String, int>{'blue': 2, 'red': 1, 'yellow': 1},
    id: 8,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'red', 'blue'],
      <String>['blue', 'red', 'yellow', 'blue', 'red', 'yellow'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 1},
    id: 9,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'red', 'blue', 'yellow'],
      <String>['yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 0, 'yellow': 2},
    id: 10,
    isTutorial: true,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'red', 'blue', 'yellow'],
      <String>['blue', 'red'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 0},
    id: 11,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'red'],
      <String>['yellow', 'red', 'blue', 'yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 1, 'yellow': 1},
    id: 12,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red'],
      <String>['yellow', 'red', 'blue', 'yellow', 'blue'],
    ],
    goal: <String, int>{'blue': 2, 'red': 0, 'yellow': 0},
    id: 13,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'yellow', 'blue', 'yellow'],
      <String>['red', 'blue', 'yellow', 'red'],
    ],
    goal: <String, int>{'blue': 0, 'red': 2, 'yellow': 1},
    id: 14,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'blue', 'red', 'yellow'],
      <String>['red', 'blue', 'yellow', 'blue', 'red'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 1},
    id: 15,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'red', 'blue'],
      <String>['yellow', 'red', 'yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 0, 'yellow': 2},
    id: 16,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue', 'yellow', 'blue', 'yellow'],
      <String>['yellow', 'red', 'blue', 'red'],
    ],
    goal: <String, int>{'blue': 2, 'red': 0, 'yellow': 1},
    id: 17,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'red', 'yellow'],
      <String>['red', 'red', 'yellow', 'blue'],
      <String>['blue', 'blue'],
    ],
    goal: <String, int>{'blue': 3, 'red': 0, 'yellow': 0},
    id: 18,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'red', 'blue', 'yellow'],
      <String>['yellow', 'red', 'yellow'],
      <String>['red', 'blue'],
    ],
    goal: <String, int>{'blue': 3, 'red': 0, 'yellow': 0},
    id: 19,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'red', 'yellow', 'yellow'],
      <String>['blue'],
      <String>['red', 'blue', 'yellow', 'red'],
    ],
    goal: <String, int>{'blue': 2, 'red': 0, 'yellow': 1},
    id: 20,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'red', 'yellow', 'yellow'],
      <String>['blue', 'red'],
      <String>['yellow', 'red', 'blue'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 1},
    id: 21,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'blue'],
      <String>['red', 'blue', 'yellow'],
      <String>['red', 'blue', 'yellow', 'yellow'],
    ],
    goal: <String, int>{'blue': 2, 'red': 0, 'yellow': 1},
    id: 22,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'blue', 'red'],
      <String>['yellow', 'yellow', 'red'],
    ],
    goal: <String, int>{'blue': 0, 'red': 1, 'yellow': 1},
    id: 23,
    isTutorial: true,
    trumpCol: 2,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'yellow', 'red'],
      <String>['blue', 'blue', 'yellow'],
    ],
    goal: <String, int>{'blue': 1, 'red': 0, 'yellow': 1},
    id: 24,
    trumpCol: 2,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['yellow', 'red', 'blue', 'blue'],
      <String>['red', 'red', 'yellow'],
      <String>['yellow', 'blue'],
    ],
    goal: <String, int>{'blue': 1, 'red': 1, 'yellow': 1},
    id: 25,
    trumpCol: 2,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['red', 'red', 'red'],
      <String>['blue', 'blue', 'yellow', 'yellow'],
      <String>['blue', 'yellow'],
    ],
    goal: <String, int>{'blue': 0, 'red': 3, 'yellow': 0},
    id: 26,
    trumpCol: 1,
  ),
  DespairLevelData(
    board: <List<String>>[
      <String>['blue', 'blue', 'yellow'],
      <String>['red', 'blue', 'red', 'yellow', 'red', 'yellow'],
    ],
    goal: <String, int>{'blue': 1, 'red': 0, 'yellow': 2},
    id: 27,
    trumpCol: 1,
  ),
];

class LevelPage extends StatelessWidget {
  const LevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.navigate_before,
            size: 40,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.all(12),
                    child: SettingsTile(),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings_outlined,
                size: 38,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9DF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Levels',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 42),
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  // For now the levels screen opens only the first level tile.
                  // Later this can be replaced with a full grid of tappable
                  // levels that each pull their own data from [levels].
                  final DespairLevelData level = levels.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LevelPageFormat(
                        board: level.board,
                        goal: level.goal,
                        no: level.id,
                        id: level.id,
                        hasHint: level.hasHint,
                        isTut: level.isTutorial,
                        trumpCol: level.trumpCol,
                      ),
                    ),
                  );
                },
                child: const LevelTile(id: 1, isTut: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
