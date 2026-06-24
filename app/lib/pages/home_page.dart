import 'package:app/games/despair/levels.dart';
import 'package:app/pages/collection_page.dart';
import 'package:app/pages/profile_page.dart';
import 'package:app/util/game_tile.dart';
import 'package:app/util/join.dart';
import 'package:app/util/puzzle_tile.dart';
import 'package:app/util/settings_tile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // ignore: non_constant_identifier_names
    List Puzzles = ["Color Topper", "New Game"];
    // ignore: non_constant_identifier_names
    List Games = ["Roop", "Compair"];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade300,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ProfilePage');
            },
            icon: const Icon(Icons.navigate_before, size: 36),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.all(12),
                    child: SettingsTile(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 44),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Container(
              // width: double.infinity,
              color: Colors.grey.shade300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "App Name",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 52, top: 32),
                    child: Text(
                      "Puzzles",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: Puzzles.length,
                      itemBuilder: (context, index) {
                        return PuzzleTile(
                          title: Puzzles[index],
                          onTap: index == 0
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LevelPage(),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 48),
                    child: Text(
                      "Games",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: Games.length,
                      itemBuilder: (context, index) {
                        return GameTile(title: Games[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      right: 32,
                      bottom: 24,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.all(12),
                              child: JoinTile(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            82,
                            79,
                            95,
                          ),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Join room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CollectionPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
