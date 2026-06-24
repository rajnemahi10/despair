import 'package:app/pages/home_page.dart';
import 'package:app/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/collection_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/HomePage': (context) => const HomePage(),
        '/ProfilePage': (context) => const ProfilePage(),
        '/CollectionPage': (context) => const CollectionPage(),
      },
    );
  }
}
