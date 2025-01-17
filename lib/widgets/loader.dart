import 'package:flutter/material.dart';

// Loader animation widget
class LoaderAnimation extends StatelessWidget {
  const LoaderAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Dot(color: Colors.blue),
        SizedBox(width: 4),
        Dot(color: Colors.blue[300]!),
        SizedBox(width: 4),
        Dot(color: Colors.blue[100]!),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;

  const Dot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
