import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return baseSize * 0.85;
    if (width < 600) return baseSize * 0.9;
    if (width < 900) return baseSize * 1.0;
    return baseSize * 1.1;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return const EdgeInsets.all(8.0);
    if (width < 600) return const EdgeInsets.all(12.0);
    return const EdgeInsets.all(24.0);
  }

  static double getAppBarHeight(BuildContext context) {
    return isMobile(context) ? 48.0 : 56.0;
  }

  static double getBottomNavHeight(BuildContext context) {
    return isMobile(context) ? 56.0 : 64.0;
  }
}
