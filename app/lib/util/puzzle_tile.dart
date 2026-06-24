import 'package:flutter/material.dart';

class PuzzleTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const PuzzleTile({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 350,
          height: 100,
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
      ),
    );
  }
}
