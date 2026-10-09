import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Widget? trailing;

  const AppSearchField({
    super.key,
    this.hintText = 'Search...',
    required this.onChanged,
    this.controller,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: trailing,
      ),
    );
  }
}
