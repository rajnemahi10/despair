import 'package:flutter/material.dart';
import 'package:app/games/despair/level_page.dart';
import 'package:app/util/level_tile.dart';
import 'package:app/util/settings_tile.dart';

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LevelPageFormat(
                        board: [
                          ['yellow', 'blue', 'red'],
                        ],
                        goal: {'blue': 0, 'red': 1, 'yellow': 0},
                        no: 1,
                        id: 1,
                        hasHint: false,
                        isTut: true,
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
