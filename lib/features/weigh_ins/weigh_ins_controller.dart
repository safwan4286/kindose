import 'package:flutter/material.dart' show BuildContext;
import 'package:get/get.dart';

import '../../models/logs.dart';
import '../../resources/date_utils.dart';
import '../../services/haptics/haptics.dart';
import '../../services/plus/access_service.dart';
import '../../services/tracker_service.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/k_date_picker.dart';
import '../../widgets/k_ruler.dart';
import '../../widgets/toast.dart';
import '../home/weight_sheet.dart';

/// Weigh-ins screen: every weigh-in, newest first, grouped by month.
/// Tap opens the weight screen on that day (edit or delete there); swipe
/// deletes with Undo.
class WeighInsController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  void watch() {
    tracker.weights.length;
    tracker.profile.value;
  }

  bool get useKg => tracker.profile.value?.useKg ?? true;
  String get unit => useKg ? 'kg' : 'lb';
  double _shown(double kg) => useKg ? kg : kg * Imperial.lbPerKg;
  String fmt(double kg) => '${_shown(kg).toStringAsFixed(1)} $unit';

  /// "−0.6 kg" / "+0.4 kg" / "±0.0 kg".
  String signed(double kgDiff) {
    final v = double.parse(_shown(kgDiff).toStringAsFixed(1));
    final sign = v < 0 ? '−' : (v > 0 ? '+' : '±');
    return '$sign${v.abs().toStringAsFixed(1)} $unit';
  }

  /// ("October 2026", [(entry, change since the one before)]), newest
  /// month first. The first weigh-in ever has no change.
  List<(String, List<(WeightEntry, double?)>)> get groups {
    final w = tracker.weights;
    final out = <(String, List<(WeightEntry, double?)>)>[];
    for (var i = w.length - 1; i >= 0; i--) {
      final e = w[i];
      final month = '${Dates.months[e.date.month - 1]} ${e.date.year}';
      final row = (e, i == 0 ? null : e.kg - w[i - 1].kg);
      if (out.isEmpty || out.last.$1 != month) {
        out.add((month, [row]));
      } else {
        out.last.$2.add(row);
      }
    }
    return out;
  }

  void edit(WeightEntry w) => showWeightSheet(day: w.date);

  /// Pick the day first, then the usual weight screen on that day.
  Future<void> logPast(BuildContext context) async {
    final today = Dates.dateOnly(DateTime.now());
    final p = tracker.profile.value;
    final start = p?.treatmentStartedAt ?? p?.startedAt ?? today;
    final first = Dates.addDays(Dates.dateOnly(start), -30);
    final day = await showKDatePicker(
      context: context,
      initialDate: Dates.addDays(today, -1),
      firstDate: first.isAfter(today) ? today : first,
      lastDate: today,
      title: 'When did you weigh in?',
      marked: (d) => tracker.weights.any((w) => Dates.sameDay(w.date, d)),
    );
    if (day == null) return;
    await showWeightSheet(day: day);
  }

  /// Paywall, then "Delete this weigh-in?". Used before the row slides.
  Future<bool> confirmDelete(WeightEntry w) async {
    if (!await AccessService.ensure()) return false;
    return confirmRemove(
      title: 'Delete this weigh-in?',
      message:
          '${fmt(w.kg)} on ${Dates.shortWithDay(w.date)}. It comes off your '
          'chart and progress.',
    );
  }

  /// Swipe to delete (already asked), with Undo.
  Future<void> delete(WeightEntry w) async {
    final old = await tracker.removeWeight(w.date);
    if (old == null) return;
    Haptics.instance.mediumImpact();
    showUndoToast(
      'Weigh-in deleted',
      () => tracker.addWeight(old.kg, old.date),
    );
  }
}
