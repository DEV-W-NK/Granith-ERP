import 'package:flutter/widgets.dart';

abstract final class ResponsiveLayout {
  // Existing callers mostly use `< compact`; 769 keeps a 768px viewport compact.
  static const double compact = 769;
  static const double medium = 900;
  static const double expanded = 1200;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < expanded;
  static bool isExpanded(double width) => width >= expanded;

  static EdgeInsets pagePadding(double width) {
    if (width < 380) return const EdgeInsets.all(12);
    if (width < compact) return const EdgeInsets.all(16);
    if (width < expanded) return const EdgeInsets.all(20);
    return const EdgeInsets.all(28);
  }

  static int columnsFor(
    double width, {
    int compactColumns = 1,
    int mediumColumns = 2,
    int expandedColumns = 3,
  }) {
    if (width < compact) return compactColumns;
    if (width < 1080) return mediumColumns;
    return expandedColumns;
  }

  static double gap(double width) {
    if (width < 380) return 10;
    if (width < compact) return 12;
    if (width < expanded) return 16;
    return 20;
  }
}
