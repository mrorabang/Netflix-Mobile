import 'package:flutter/material.dart';

class RoundText extends StatelessWidget {
  const RoundText({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x2EFFFFFF), width: 0.7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFECECF4),
        ),
      ),
    );
  }
}
