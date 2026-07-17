// view/calculator_coming_soon_screen.dart
//
// Placeholder for the 4 calculators whose POST payload/response you haven't
// shared yet. Once you send those, this gets replaced the same way
// PaintCalculatorScreen was built.

import 'package:flutter/material.dart';

class CalculatorComingSoonScreen extends StatelessWidget {
  final String title;
  const CalculatorComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title is coming soon.'),
      ),
    );
  }
}