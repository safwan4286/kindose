import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/theme/theme.dart';

/// Pops the top route (page, sheet or dialog) directly on the navigator.
/// In GetX 4, `Get.back()` closes an open snackbar instead of the route,
/// so a fast second tap could leave a sheet open. This never does.
void popRoute() => Get.key.currentState?.pop();

const Duration _toastDuration = Duration(milliseconds: 2200);

/// The plain toast on screen now, so repeat taps don't stack copies.
String? _shownMessage;
DateTime? _shownAt;

/// Short confirmation at the bottom of the screen, above the tab bar.
///
/// Safe to call on every tap: the same message is ignored while it is
/// still showing, and a different message replaces the current toast
/// instead of queueing behind it.
void showToast(String message) {
  final now = DateTime.now();
  final shownAt = _shownAt;
  if (message == _shownMessage && shownAt != null && now.difference(shownAt) < _toastDuration) {
    return;
  }
  _shownMessage = message;
  _shownAt = now;
  Get.closeCurrentSnackbar();
  Get.rawSnackbar(
    messageText: Text(
      message,
      style: AppText.bodyStrong.copyWith(color: AppColors.white),
    ),
    backgroundColor: AppColors.ink,
    borderRadius: 18,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
    duration: _toastDuration,
    animationDuration: const Duration(milliseconds: 300),
    snackPosition: SnackPosition.BOTTOM,
  );
}

/// Toast with an Undo button. [onUndo] runs at most once.
void showUndoToast(String message, Future<void> Function() onUndo) {
  var done = false;
  // Replaces any plain toast, so the next one may show again.
  _shownMessage = null;
  Get.closeCurrentSnackbar();
  Get.rawSnackbar(
    messageText: Text(
      message,
      style: AppText.bodyStrong.copyWith(color: AppColors.white),
    ),
    mainButton: TextButton(
      onPressed: () async {
        if (done) return;
        done = true;
        Get.closeCurrentSnackbar();
        await onUndo();
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lime,
        minimumSize: const Size(64, 44),
      ),
      child: Text('Undo', style: AppText.title.copyWith(color: AppColors.lime)),
    ),
    backgroundColor: AppColors.ink,
    borderRadius: 18,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
    duration: const Duration(milliseconds: 3500),
    animationDuration: const Duration(milliseconds: 300),
    snackPosition: SnackPosition.BOTTOM,
  );
}
