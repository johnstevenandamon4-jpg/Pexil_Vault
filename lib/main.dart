import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PExilVaultApp());
}

class PExilVaultApp extends StatelessWidget {
  const PExilVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PExil Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
