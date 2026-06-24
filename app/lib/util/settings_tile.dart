import 'package:flutter/material.dart';

class SettingsTile extends StatefulWidget {
  const SettingsTile({super.key});

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  double soundValue = 0.7;
  double musicValue = 0.5;
  String language = 'English';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 131, 130, 139),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.volume_up, size: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: soundValue,
                    onChanged: (value) {
                      setState(() {
                        soundValue = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.music_note, size: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: musicValue,
                    onChanged: (value) {
                      setState(() {
                        musicValue = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: DropdownButton<String>(
                value: language,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    language = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
