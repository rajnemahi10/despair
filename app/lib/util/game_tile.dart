import 'package:flutter/material.dart';

class GameTile extends StatelessWidget {
  final String title;

  const GameTile({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
          color: const Color.fromARGB(234, 189, 185, 185),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.only(left: 20),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
