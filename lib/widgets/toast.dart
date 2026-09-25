import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/theme/theme.dart';

/// Pops the top route (page, sheet or dialog) directly on the navigator.
/// In GetX 4, `Get.back()` closes an open snackbar instead of the route,
/// so a fast second tap could leave a sheet open. This never does.
void popRoute() => Get.key.currentState?.pop();

/// Short confirmation at the bottom of the screen, above the tab bar.
void showToast(String message) {
  Get.rawSnackbar(
    messageText: Text(message, style: AppText.bodyStrong.copyWith(color: AppColors.white)),
    backgroundColor: AppColors.ink,
    borderRadius: 18,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
    duration: const Duration(milliseconds: 2200),
    animationDuration: const Duration(milliseconds: 300),
    snackPosition: SnackPosition.BOTTOM,
  );
}
