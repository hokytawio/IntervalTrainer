import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interval Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF0A5BE0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A5BE0)),
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}
