import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/catalog.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

class LogDoseController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();
  final TextEditingController noteCtrl = TextEditingController();

  late final Rx<DateTime> takenAt = DateTime.now().obs;
  late final RxString site = tracker.nextSiteId.obs;
  final RxInt pain = 0.obs;
  final RxBool showNote = false.obs;
  final RxBool saving = false.obs;

  bool get isTablet => tracker.profile.value?.form == 'tablet';
  String get suggestedSite => tracker.nextSiteId;
  String? get lastSite => tracker.lastSiteId;

  String get medicineTitle {
    final p = tracker.profile.value;
    if (p == null) return 'Dose';
    return '${Catalog.medicine(p.medicineId).name} · ${Catalog.mg(p.strengthMg)} mg';
  }

  Medicine? get medicine {
    final p = tracker.profile.value;
    return p == null ? null : Catalog.medicine(p.medicineId);
  }

  String get formLabel => Catalog.formLabel(tracker.profile.value?.form ?? 'pen');

  @override
  void onClose() {
    noteCtrl.dispose();
    super.onClose();
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: takenAt.value,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
      helpText: 'When did you take it?',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(takenAt.value),
    );
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    takenAt.value = picked.isAfter(now) ? now : picked;
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    try {
      await tracker.addDose(
        takenAt: takenAt.value,
        site: isTablet ? '' : site.value,
        pain: isTablet ? 0 : pain.value,
        note: noteCtrl.text,
      );
      popRoute();
      showToast('Dose saved. Nice work.');
    } catch (_) {
      showToast("Couldn't save. Please try again.");
    } finally {
      saving.value = false;
    }
  }
}
