import 'package:get/get.dart';

import '../services/region/region.dart';
import '../services/tracker_service.dart';

/// Water is always stored in ml. This turns it into what the person reads:
/// litres / ml, or US fluid ounces (`UserProfile.useOz`, Me → App → Water).
///
/// Reads the profile, so text built inside an `Obx` updates when the
/// setting changes.
class Water {
  Water._();

  static const double mlPerOz = 29.5735;

  /// Fluid ounces for this person: their setting, else US phones.
  static bool get oz {
    if (Get.isRegistered<TrackerService>()) {
      final p = Get.find<TrackerService>().profile.value;
      if (p != null) return p.useOz;
    }
    return Region.prefersOunces;
  }

  static double toOz(int ml) => ml / mlPerOz;
  static int fromOz(double oz) => (oz * mlPerOz).round();

  /// Number only, in the big unit: "1.25" (litres) or "42" (fl oz).
  static String total(int ml) => oz ? _oz(ml) : litres(ml);

  /// "L" or "fl oz", after [total].
  static String get unit => oz ? 'fl oz' : 'L';

  /// For screen readers, after [total].
  static String get unitWords => oz ? 'fluid ounces' : 'litres';

  /// One amount with its unit: "250 ml", "1.5 L", "8 fl oz".
  static String amount(int ml) {
    if (oz) return '${_oz(ml)} fl oz';
    return ml >= 1000 ? '${litres(ml)} L' : '$ml ml';
  }

  /// A total with its unit: "2.5 L" or "85 fl oz".
  static String totalWithUnit(int ml) => '${total(ml)} $unit';

  /// The glass used for counting: 250 ml, or 8 fl oz.
  static int get glassMl => oz ? fromOz(8) : 250;

  /// "250 ml a glass" / "8 fl oz a glass".
  static String get glassLabel => '${amount(glassMl)} a glass';

  /// "2.5" from 2500, "1.25" from 1250, "2" from 2000.
  static String litres(int ml) =>
      (ml / 1000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  /// Whole ounces, one decimal for small amounts that aren't close to
  /// whole (16.9 for a 500 ml bottle).
  static String _oz(int ml) {
    final v = toOz(ml);
    final r = v.round();
    if (v >= 20 || (v - r).abs() < 0.15) return '$r';
    return v.toStringAsFixed(1);
  }
}
