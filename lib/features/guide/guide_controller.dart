import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/routes.dart';
import '../../services/haptics/haptics.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

/// Open with `fromLogDose: true` as the argument when Log dose is already
/// open under the guide, so "Log this dose" just goes back to it.
class GuideArgs {
  const GuideArgs({this.fromLogDose = false});

  final bool fromLogDose;
}

/// Calm, 5-step walk-through for an injection day: get ready, pick the
/// spot, breathe, inject (with an optional hold timer), after.
///
/// It never says how to use a specific pen: the leaflet is always the
/// source, and every step says so.
class GuideController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  static const int stepCount = 5;
  static const List<int> holdChoices = [5, 6, 10, 15];
  static const String _holdKey = 'guideHoldSecs';

  final RxInt step = 0.obs;
  final RxList<bool> checks = <bool>[false, false, false, false].obs;

  /// Hold timer: chosen length, seconds left, running.
  final RxInt holdSecs = 10.obs;
  final RxInt remaining = 10.obs;
  final RxBool running = false.obs;
  final RxBool held = false.obs;
  Timer? _timer;

  late final bool fromLogDose;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    fromLogDose = arg is GuideArgs && arg.fromLogDose;
    final saved = Hive.box<dynamic>('settings').get(_holdKey);
    if (saved is int && holdChoices.contains(saved)) holdSecs.value = saved;
    remaining.value = holdSecs.value;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------- words

  static const List<String> checkItems = [
    'Wash your hands',
    'Check the name, dose and expiry',
    'Pen at room temperature if your leaflet says so',
    'Swab and sharps bin nearby',
  ];

  static const List<(String, String)> afterItems = [
    ('Put the pen or needle in a sharps bin', 'Never loose in the bin at home'),
    ('A little redness is common', 'Press gently. Don’t rub.'),
    ('Log it in Kindose', 'We’ll suggest the next spot'),
  ];

  String get nextSiteId => tracker.nextSiteId;
  String get nextSiteName => Catalog.siteName(nextSiteId);

  String get caps => const ['GET READY', 'PICK YOUR SPOT', 'BREATHE', 'INJECT', 'AFTER'][step.value];

  String get title => switch (step.value) {
    0 => 'Take a moment to set up',
    1 => '$nextSiteName today',
    2 => 'Settle your breathing',
    3 => 'Follow your pen’s steps',
    _ => 'Nicely done',
  };

  String get body {
    switch (step.value) {
      case 0:
        return 'Nothing to rush. Tick things off as you go.';
      case 1:
        final last = tracker.lastSiteId;
        final lastName = last == null ? null : Catalog.siteName(last);
        final why = lastName == null
            ? 'Rotating spots lets each one rest.'
            : 'You used $lastName last time. Rotating lets each spot rest.';
        return '$why Skip skin that is sore, bruised or scarred.';
      case 2:
        return 'A few slow breaths relax your muscles, which can make it feel easier.';
      case 3:
        return 'Press and hold for as long as your leaflet says. Use the timer if counting helps.';
      default:
        return 'A couple of last things, then log it.';
    }
  }

  String get cta => switch (step.value) {
    2 => 'I’m ready',
    3 => 'Done',
    4 => 'Log this dose',
    _ => 'Next',
  };

  // -------------------------------------------------------------- actions

  void toggleCheck(int i) {
    Haptics.instance.selectionClick();
    checks[i] = !checks[i];
  }

  void next() {
    if (step.value >= stepCount - 1) {
      _finish();
      return;
    }
    Haptics.instance.lightImpact();
    _stopTimer();
    step.value++;
  }

  void back() {
    if (step.value == 0) return;
    Haptics.instance.selectionClick();
    _stopTimer();
    step.value--;
  }

  void close() {
    _stopTimer();
    popRoute();
  }

  void _finish() {
    Haptics.instance.mediumImpact();
    _stopTimer();
    if (fromLogDose) {
      popRoute();
    } else {
      Get.offNamed<void>(Routes.logDose);
    }
  }

  void setHold(int secs) {
    if (running.value) return;
    Haptics.instance.selectionClick();
    holdSecs.value = secs;
    remaining.value = secs;
    held.value = false;
    Hive.box<dynamic>('settings').put(_holdKey, secs);
  }

  /// Starts the hold timer, or stops and resets it while running.
  void toggleTimer() {
    if (running.value) {
      Haptics.instance.selectionClick();
      _stopTimer();
      return;
    }
    Haptics.instance.mediumImpact();
    held.value = false;
    remaining.value = holdSecs.value;
    running.value = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      remaining.value--;
      if (remaining.value <= 0) {
        _timer?.cancel();
        running.value = false;
        held.value = true;
        remaining.value = 0;
        Haptics.instance.heavyImpact();
      } else {
        Haptics.instance.selectionClick();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    running.value = false;
    held.value = false;
    remaining.value = holdSecs.value;
  }
}
