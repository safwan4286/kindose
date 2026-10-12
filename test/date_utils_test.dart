import 'package:flutter_test/flutter_test.dart';
import 'package:kindose/resources/date_utils.dart';

// Run with a DST zone to cover clock changes, e.g.
// TZ=Europe/London flutter test test/date_utils_test.dart
void main() {
  group('Dates across clock changes', () {
    // Clocks go back: 25 Oct 2026 (Europe), 1 Nov 2026 (US).
    // Clocks go forward: 29 Mar 2026 (Europe), 8 Mar 2026 (US).
    final changeDays = [
      DateTime(2026, 10, 25),
      DateTime(2026, 11, 1),
      DateTime(2026, 3, 29),
      DateTime(2026, 3, 8),
    ];

    test('atMinutes keeps the wall-clock time', () {
      for (final d in changeDays) {
        final at = Dates.atMinutes(d, 8 * 60);
        expect((at.year, at.month, at.day), (d.year, d.month, d.day));
        expect((at.hour, at.minute), (8, 0));
      }
    });

    test('addDays lands on the next and previous calendar day', () {
      for (final d in changeDays) {
        final next = Dates.addDays(d, 1);
        final prev = Dates.addDays(d, -1);
        expect(Dates.daysBetween(d, next), 1);
        expect(Dates.daysBetween(prev, d), 1);
        expect(next.hour, 0);
        expect(prev.hour, 0);
      }
    });

    test('a week later is the same weekday and time', () {
      final dose = DateTime(2026, 10, 18, 8);
      final next = Dates.addDays(dose, 7);
      expect(next, DateTime(2026, 10, 25, 8));
      expect(next.weekday, DateTime.sunday);
    });
  });
}
