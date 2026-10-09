import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final BookAvailability availability;
  const StatusBadge({super.key, required this.availability});

  @override
  Widget build(BuildContext context) {
    final isAvailable = availability == BookAvailability.available;
    final color = isAvailable ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Available' : 'Issued',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
