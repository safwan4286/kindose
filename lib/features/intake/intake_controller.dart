import 'package:get/get.dart';

import '../../resources/catalog.dart';
import '../../resources/images.dart';
import '../../services/tracker_service.dart';
import '../../widgets/toast.dart';

class WaterSize {
  const WaterSize(this.id, this.name, this.ml, this.icon);

  final String id;
  final String name;
  final int ml;
  final String icon;
}

/// Add protein (grams) or water (ml). Opened with 'protein' or 'water'.
class IntakeController extends GetxController {
  final TrackerService tracker = Get.find<TrackerService>();

  static const List<WaterSize> waterSizes = [
    WaterSize('glass', 'Glass', 250, Img3d.droplet),
    WaterSize('bottle', 'Bottle', 500, Img3d.droplet),
    WaterSize('milk', 'Milk', 200, Img3d.milk),
    WaterSize('shake', 'Shake', 300, Img3d.whey),
  ];

  late final RxString tab = (Get.arguments == 'water' ? 'water' : 'protein').obs;
  final RxInt proteinG = 24.obs;
  final RxInt waterMl = 250.obs;
  final RxString proteinPick = 'whey'.obs;
  final RxString waterPick = 'glass'.obs;
  final RxBool saving = false.obs;

  bool get isProtein => tab.value == 'protein';

  List<Food> get usualFoods =>
      (tracker.profile.value?.vegDiet ?? false) ? Catalog.vegFoods : Catalog.everydayFoods;

  int get amount => isProtein ? proteinG.value : waterMl.value;
  int get todayBase => isProtein ? tracker.today.proteinG : tracker.today.waterMl;
  int get goal => isProtein
      ? (tracker.profile.value?.proteinGoalG ?? 100)
      : (tracker.profile.value?.waterGoalMl ?? 2500);

  void decrease() {
    if (isProtein) {
      proteinG.value = (proteinG.value - 1).clamp(1, 200);
    } else {
      waterMl.value = (waterMl.value - 50).clamp(50, 3000);
    }
  }

  void increase() {
    if (isProtein) {
      proteinG.value = (proteinG.value + 1).clamp(1, 200);
    } else {
      waterMl.value = (waterMl.value + 50).clamp(50, 3000);
    }
  }

  void pickFood(Food f) {
    proteinPick.value = f.id;
    proteinG.value = f.grams;
  }

  void pickWater(WaterSize w) {
    waterPick.value = w.id;
    waterMl.value = w.ml;
  }

  String formatWater(int ml) {
    final l = ml / 1000;
    return '${l.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '')} L';
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    try {
      final message = isProtein ? 'Added ${proteinG.value} g protein' : 'Added ${waterMl.value} ml water';
      if (isProtein) {
        await tracker.addProtein(proteinG.value);
      } else {
        await tracker.addWater(waterMl.value);
      }
      popRoute();
      showToast(message);
    } finally {
      saving.value = false;
    }
  }
}
