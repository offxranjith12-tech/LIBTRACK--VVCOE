import 'dart:io';

import 'package:flutter/material.dart';

/// Shows the student's profile photo if one has been set (either a local
/// file picked on-device, or a network URL returned by the backend),
/// otherwise falls back to a circular initial avatar.
class StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  const StudentAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 30,
    this.backgroundColor = Colors.white24,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('http')) {
        image = NetworkImage(photoUrl!);
      } else {
        final file = File(photoUrl!);
        if (file.existsSync()) {
          image = FileImage(file);
        }
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: foregroundColor, fontSize: radius * 0.7, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
