import 'package:flutter/services.dart';

/// Centralized haptic feedback helpers.
///
/// Uses Flutter's built-in [HapticFeedback] — no extra packages or
/// platform permissions required. Works on both iOS and Android.
class Haptics {
  Haptics._();

  /// Light tap — button presses, selections, toggles.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Medium tap — confirming an action (save, update, join).
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy tap — major milestone (finish book, complete challenge, level up).
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Success pattern — positive events (streak, badge earned, goal reached).
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Warning / destructive — delete, leave, sign out.
  static Future<void> warning() => HapticFeedback.vibrate();

  /// Selection change — picker, slider, bottom sheet option.
  static Future<void> selection() => HapticFeedback.selectionClick();
}
