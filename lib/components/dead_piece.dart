import 'package:flutter/material.dart';

class DeadPiece extends StatelessWidget {
  final String imagePath;
  final bool isWhite;

  const DeadPiece({
    Key? key,
    required this.imagePath,
    required this.isWhite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isWhite ? Colors.grey[400] : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Image.asset(
        imagePath,
        color: isWhite ? Colors.white : Colors.black,
      ),
    );
  }
}
