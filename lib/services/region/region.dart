import 'dart:ui';

/// Rough region checks without asking for location. Used only to tailor
/// content (e.g. the Jain diet option), never for anything important.
class Region {
  Region._();

  /// True when the phone looks Indian: an Indian locale on the device, or
  /// the IST clock (+05:30, shared only with Sri Lanka).
  static bool get isIndia {
    final locales = PlatformDispatcher.instance.locales;
    if (locales.any((l) => l.countryCode?.toUpperCase() == 'IN')) return true;
    return DateTime.now().timeZoneOffset == const Duration(hours: 5, minutes: 30);
  }
}
