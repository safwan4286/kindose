import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class Haptics {
  static Haptics? _instance;

  Haptics._internal();

  static Haptics get instance {
    _instance ??= Haptics._internal();
    return _instance!;
  }

  void lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  void mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  void heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  void selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  void vibrate() async {
    await HapticFeedback.vibrate();
  }
}

class VibrationUtil {
  // Light impact vibration
  static Future<void> lightImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 25);
    }
  }

  // Medium impact vibration
  static Future<void> mediumImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100, amplitude: 125);
    }
  }

  // Heavy impact vibration
  static Future<void> heavyImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150, amplitude: 255);
    }
  }

  // Selection click vibration
  static Future<void> selectionClick() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30, amplitude: 40);
    }
  }

  // General vibration
  static Future<void> vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }
}