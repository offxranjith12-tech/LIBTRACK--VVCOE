import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  final String title;
  final String colorHex;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.title,
    required this.colorHex,
    this.width = 64,
    this.height = 90,
  });

  Color get _color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final initials = title.trim().isEmpty
        ? '?'
        : title.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color, _color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: _color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, color: Colors.white.withOpacity(0.85), size: width * 0.32),
          const SizedBox(height: 4),
          Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.22,
            ),
          ),
        ],
      ),
    );
  }
}
