import 'package:flutter/material.dart';
import 'screens/auth_screen.dart'; // 👈 Importe ton écran de login (ajuste le chemin si besoin)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YMS Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(), // 👈 L'application démarre directement ici
    );
  }
}