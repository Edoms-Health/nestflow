import 'package:flutter/material.dart';

enum TodoPriority {
  low,
  medium,
  high,
  urgent;

  /// Todoist-style P1-P4 label, P1 = most urgent
  String get shortLabel {
    switch (this) {
      case TodoPriority.urgent:
        return 'P1';
      case TodoPriority.high:
        return 'P2';
      case TodoPriority.medium:
        return 'P3';
      case TodoPriority.low:
        return 'P4';
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
      case TodoPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TodoPriority.low:
        return const Color(0xFF1abc9c);
      case TodoPriority.medium:
        return const Color(0xFFFFC107);
      case TodoPriority.high:
        return const Color(0xFFD32F2F);
      case TodoPriority.urgent:
        return const Color(0xFF8E24AA);
    }
  }

  IconData get icon {
    switch (this) {
      case TodoPriority.low:
        return Icons.arrow_downward_rounded;
      case TodoPriority.medium:
        return Icons.remove_rounded;
      case TodoPriority.high:
        return Icons.arrow_upward_rounded;
      case TodoPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}
