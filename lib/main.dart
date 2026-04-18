import 'package:flutter/material.dart';
import 'app_config.dart';
import 'screens/quiz_screen.dart';

void main() {
  AppConfig.validate();
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const QuizScreen(),
    );
  }
}
