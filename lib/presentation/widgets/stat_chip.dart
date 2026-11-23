import 'package:flutter/material.dart';

// A small reusable "number over label" chip, used three times in the
// summary row but generic enough to reuse elsewhere.
class StatChip extends StatelessWidget {
  const StatChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$value',
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
