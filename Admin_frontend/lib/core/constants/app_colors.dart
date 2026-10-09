import 'package:flutter/material.dart';

/// V V College of Engineering — LibTrack brand palette.
///
/// `card`, `background`, `text`, `textSecondary`, and `divider` are
/// theme-aware: they flip to their dark-mode counterparts whenever
/// [AppColors.isDark] is updated (done once per frame, from the app root,
/// right before MaterialApp builds — see main.dart). This is what makes Dark
/// Mode apply to every screen's cards/text/dividers, not just the Scaffold's
/// default background.
class AppColors {
  AppColors._();

  static bool _isDark = false;
  static bool get isDark => _isDark;
  static set isDark(bool value) => _isDark = value;

  static const Color primary = Color(0xFFB71C1C);
  static const Color primaryDark = Color(0xFF7F0000);
  static const Color secondary = Color(0xFFD32F2F);

  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textLight = Color(0xFF212121);
  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _dividerLight = Color(0xFFE5E7EB);

  // Public const aliases for the light variants — used inside const
  // ThemeData construction (AppTheme.light), where a dynamic getter can't
  // be used. Everywhere else in the app, prefer the dynamic getters below
  // (background/card/text/textSecondary/divider), which flip with dark mode.
  static const Color backgroundLight = _backgroundLight;
  static const Color cardLight = _cardLight;
  static const Color textLight = _textLight;
  static const Color textSecondaryLight = _textSecondaryLight;
  static const Color dividerLight = _dividerLight;

  static Color get background => _isDark ? backgroundDark : _backgroundLight;
  static Color get card => _isDark ? cardDark : _cardLight;
  static Color get text => _isDark ? textDark : _textLight;
  static Color get textSecondary => _isDark ? textSecondaryDark : _textSecondaryLight;
  static Color get divider => _isDark ? dividerDark : _dividerLight;

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // Dark mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFECECEC);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color dividerDark = Color(0xFF2D2D2D);

  // Status colors
  static const Color available = Color(0xFF2E7D32);
  static const Color issued = Color(0xFFF9A825);
  static const Color overdue = Color(0xFFC62828);
  static const Color reserved = Color(0xFF1565C0);

  static const List<Color> chartPalette = [
    primary,
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8E0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
