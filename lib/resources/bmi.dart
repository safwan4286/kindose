/// Body mass index helpers. WHO adult ranges; shown as a rough guide only.
enum BmiRange { below, healthy, above, obesity }

class Bmi {
  Bmi._();

  /// Scale shown on the BMI bar: 0 to [scaleMax].
  static const double scaleMax = 40;

  static double? of(double kg, double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final m = heightCm / 100;
    return kg / (m * m);
  }

  static BmiRange range(double bmi) {
    if (bmi < 18.5) return BmiRange.below;
    if (bmi < 25) return BmiRange.healthy;
    if (bmi < 30) return BmiRange.above;
    return BmiRange.obesity;
  }

  static String label(BmiRange r) => switch (r) {
    BmiRange.below => 'Below healthy range',
    BmiRange.healthy => 'Healthy range',
    BmiRange.above => 'Above healthy range',
    BmiRange.obesity => 'Obesity range',
  };
}
