import '../services/region/region.dart';

/// Small date helpers so we don't need the intl package yet.
/// All values are shown in the phone's local time.
class Dates {
  Dates._();

  static const List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `DateTime.weekday` is 1 (Mon) … 7 (Sun).
  static String weekdayName(int weekday) => weekdays[(weekday - 1) % 7];
  static String weekdayShort(int weekday) =>
      weekdayName(weekday).substring(0, 3);
  static String monthShort(int month) => months[month - 1].substring(0, 3);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String key(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int daysBetween(DateTime from, DateTime to) =>
      (dateOnly(to).difference(dateOnly(from)).inHours / 24).round();

  /// Month before day ("Sep 25") on US phones, day first elsewhere.
  static bool get monthFirst => Region.country == 'US';

  /// "25 Sep" or "Sep 25".
  static String dayMonth(int day, String month) =>
      monthFirst ? '$month $day' : '$day $month';

  /// "Thursday, 25 September" / "Thursday, September 25"
  static String long(DateTime d) =>
      '${weekdayName(d.weekday)}, ${dayMonth(d.day, months[d.month - 1])}';

  /// "25 Sep" / "Sep 25"
  static String short(DateTime d) => dayMonth(d.day, monthShort(d.month));

  /// "Thu, 25 Sep" / "Thu, Sep 25"
  static String shortWithDay(DateTime d) =>
      '${weekdayShort(d.weekday)}, ${short(d)}';

  /// "9:00 AM" from minutes after midnight.
  static String timeOfDay(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }

  static String time(DateTime d) => timeOfDay(d.hour * 60 + d.minute);

  /// "2d 14h", "5h 20m", "12m"
  static String countdown(Duration left) {
    if (left.isNegative) return 'Due now';
    final d = left.inDays;
    final h = left.inHours % 24;
    final m = left.inMinutes % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// "Today", "Tomorrow", "Sunday" (within a week) or "Sun, 5 Oct".
  static String relativeDay(DateTime target, DateTime now) {
    final diff = daysBetween(now, target);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return weekdayName(target.weekday);
    return shortWithDay(target);
  }

  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
