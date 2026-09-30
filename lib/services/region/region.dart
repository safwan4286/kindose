import 'dart:ui';

/// Rough region hints from the phone's language settings, without asking
/// for location. Used only for sensible defaults (units, currency); the
/// user can change every one of them.
class Region {
  Region._();

  /// Country from the phone's locales ("US", "GB"), or '' when unknown.
  static String get country {
    for (final l in PlatformDispatcher.instance.locales) {
      final c = l.countryCode?.toUpperCase() ?? '';
      if (c.isNotEmpty) return c;
    }
    return '';
  }

  /// Body weight in pounds by default (US, UK, Liberia, Myanmar).
  static bool get prefersPounds =>
      const {'US', 'GB', 'LR', 'MM'}.contains(country);

  /// Height in feet and inches by default.
  static bool get prefersFeet => const {'US', 'GB'}.contains(country);

  static const Set<String> _euro = {
    'AT',
    'BE',
    'CY',
    'DE',
    'EE',
    'ES',
    'FI',
    'FR',
    'GR',
    'HR',
    'IE',
    'IT',
    'LT',
    'LU',
    'LV',
    'MT',
    'NL',
    'PT',
    'SI',
    'SK',
  };

  /// Currency symbol for Pens & cost. Dollar when unknown.
  static String get currencySymbol {
    final c = country;
    if (_euro.contains(c)) return '€';
    return switch (c) {
      'GB' => '£',
      'CA' => r'C$',
      'AU' => r'A$',
      'NZ' => r'NZ$',
      'IN' => '₹',
      'AE' => 'AED',
      _ => r'$',
    };
  }
}
