import 'package:flutter/material.dart';

class LevelTile extends StatelessWidget {
  const LevelTile({super.key, required this.isTut, required this.id});

  final bool isTut;
  final int id;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFD8D8DE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$id',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          if (isTut)
            const Positioned(left: 6, bottom: 6, child: _TutorialBadge()),
        ],
      ),
    );
  }
}

class _TutorialBadge extends StatelessWidget {
  const _TutorialBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFC7C7CD),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
