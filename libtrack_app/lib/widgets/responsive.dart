import 'package:flutter/material.dart';

/// Central breakpoints used across the app so every screen adapts
/// consistently between phone, tablet and desktop/laptop widths.
class Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1000;
  static const double wide = 1400;

  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wide;
}

/// Wraps page content so it never stretches edge-to-edge on large screens.
/// On phones it behaves exactly like a normal full-width column; on
/// tablets/laptops/desktops it centers the content with a comfortable
/// max width and larger side padding, similar to a responsive web layout.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  /// If null, a responsive horizontal padding (16/24/32) is applied
  /// automatically based on screen width. Pass an explicit value
  /// (e.g. EdgeInsets.zero) when the child already handles its own
  /// padding, to avoid doubling it up.
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: width >= Breakpoints.desktop
              ? 32.0
              : width >= Breakpoints.tablet
                  ? 24.0
                  : 16.0,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: resolvedPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Returns a responsive column count for grids based on available width.
int responsiveColumns(double width, {int min = 2, int max = 4, double tileWidth = 220}) {
  final count = (width / tileWidth).floor().clamp(min, max);
  return count;
}
