import 'package:bmi/constantFile.dart';
import 'package:flutter/material.dart';
import 'constantFile.dart';

class IconText extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconText({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 70.0,
          color: Colors.white, // <- Make sure icon color is visible
        ),
        const SizedBox(height: 9.0),
        Text(
          label,
          style: kLabelStyle,
        ),
      ],
    );
  }
}
