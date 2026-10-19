import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(ThrobTrading());
}

class ThrobTrading extends StatelessWidget {
  const ThrobTrading({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Throb Trading',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}


