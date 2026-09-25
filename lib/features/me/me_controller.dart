import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/routes.dart';
import '../../services/tracker_service.dart';
import '../../widgets/mood_row.dart';
import '../../widgets/toast.dart';

class MeController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final RxBool exporting = false.obs;

  bool get isDark {
    final mode = tracker.themeMode.value;
    if (mode == ThemeMode.system) return Get.isPlatformDarkMode;
    return mode == ThemeMode.dark;
  }

  void toggleDark() => tracker.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  String get medicineSub {
    final p = tracker.profile.value;
    if (p == null) return '';
    return '${Catalog.medicine(p.medicineId).name} · ${Catalog.mg(p.strengthMg)} mg · ${Catalog.formLabel(p.form)}';
  }

  String get scheduleSub {
    final p = tracker.profile.value;
    if (p == null) return '';
    final time = Dates.timeOfDay(p.shotMinutes);
    return switch (p.everyDays) {
      1 => 'Every day · $time',
      7 => '${Dates.weekdayName(p.shotWeekday)}s · $time',
      14 => 'Every other ${Dates.weekdayName(p.shotWeekday)} · $time',
      _ => 'Every ${p.everyDays} days · $time',
    };
  }

  String get goalsSub {
    final p = tracker.profile.value;
    if (p == null) return '';
    return '${p.proteinGoalG} g protein · ${(p.waterGoalMl / 1000).toStringAsFixed(1)} L water';
  }

  bool get useKg => tracker.profile.value?.useKg ?? true;

  void editPlan() => Get.toNamed<void>(Routes.editPlan);
  void openPlus() => Get.toNamed<void>(Routes.plus);

  Future<void> setUseKg(bool v) async {
    final p = tracker.profile.value;
    if (p == null) return;
    await tracker.saveProfile(p.copyWith(useKg: v));
  }

  Future<void> editProteinGoal(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    final v = await askNumber(context, title: 'Daily protein goal', unit: 'g', initial: p.proteinGoalG.toDouble(), min: 30, max: 250);
    if (v == null || v.isNaN) return;
    await tracker.saveProfile(p.copyWith(proteinGoalG: v.round()));
  }

  Future<void> editWaterGoal(BuildContext context) async {
    final p = tracker.profile.value;
    if (p == null) return;
    final v = await askNumber(context, title: 'Daily water goal', unit: 'L', initial: p.waterGoalMl / 1000, min: 1, max: 6);
    if (v == null || v.isNaN) return;
    await tracker.saveProfile(p.copyWith(waterGoalMl: (v * 1000).round()));
  }

  // ---------------------------------------------------------------- export

  Future<void> exportJson() async {
    const encoder = JsonEncoder.withIndent('  ');
    await _share({'Kindose-export.json': encoder.convert(tracker.exportAll())});
  }

  Future<void> exportCsv() async {
    String esc(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final doses = StringBuffer('date,time,medicine,strength_mg,site,pain_0_10,note\n');
    for (final d in tracker.doses.reversed) {
      doses.writeln([
        Dates.key(d.takenAt),
        Dates.time(d.takenAt),
        Catalog.medicine(d.medicineId).name,
        d.strengthMg,
        d.site.isEmpty ? '' : Catalog.siteName(d.site),
        d.site.isEmpty ? '' : d.pain,
        d.note,
      ].map(esc).join(','));
    }

    final days = StringBuffer('date,protein_g,water_ml,mood,symptoms,nausea,food_noise,appetite,note\n');
    final sorted = tracker.days.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (final d in sorted) {
      days.writeln([
        d.key,
        d.proteinG,
        d.waterMl,
        d.mood == null ? '' : Catalog.moods[d.mood!.clamp(0, 4)].label,
        d.symptoms.map((s) => Catalog.symptoms[s] ?? s).join('; '),
        _level(d.nausea, const ['mild', 'moderate', 'severe']),
        _level(d.foodNoise, const ['quiet', 'some', 'loud']),
        _level(d.appetite, const ['low', 'normal', 'high']),
        d.note,
      ].map(esc).join(','));
    }

    final weights = StringBuffer('date,weight_kg\n');
    for (final w in tracker.weights) {
      weights.writeln('${w.key},${w.kg.toStringAsFixed(2)}');
    }

    await _share({
      'Kindose-doses.csv': doses.toString(),
      'kindose-days.csv': days.toString(),
      'kindose-weights.csv': weights.toString(),
    });
  }

  String _level(int? v, List<String> names) => v == null || v < 0 || v >= names.length ? '' : names[v];

  Future<void> _share(Map<String, String> files) async {
    if (exporting.value) return;
    exporting.value = true;
    try {
      final dir = await getTemporaryDirectory();
      final xfiles = <XFile>[];
      for (final e in files.entries) {
        final f = File('${dir.path}/${e.key}');
        await f.writeAsString(e.value, flush: true);
        xfiles.add(XFile(f.path));
      }
      final size = Get.size;
      await SharePlus.instance.share(
        ShareParams(
          files: xfiles,
          subject: 'My Kindose data',
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
        ),
      );
    } catch (_) {
      showToast("Couldn't export. Please try again.");
    } finally {
      exporting.value = false;
    }
  }

  // ---------------------------------------------------------------- delete

  Future<void> confirmDeleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all my data?'),
        content: const Text(
          'This removes every dose, check-in, weigh-in and setting from this phone. It cannot be undone. '
          'Export first if you want a copy.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await tracker.deleteAll();
    Get.offAllNamed<void>(Routes.welcome);
  }
}
