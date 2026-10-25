import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import 'buttons.dart';
import 'k_sheet.dart';

/// Asks before removing something that matters (a dose, a weigh-in, a
/// purchase): a red [action] button and Cancel. True only when confirmed;
/// dismissing the sheet counts as Cancel.
Future<bool> confirmRemove({
  required String title,
  required String message,
  String action = 'Delete',
}) async {
  Haptics.instance.mediumImpact();
  final ok = await Get.bottomSheet<bool>(
    _ConfirmSheet(title: title, message: message, action: action),
    isScrollControlled: true,
  );
  return ok ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final String action;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      title: title,
      sub: message,
      children: [
        SizedBox(height: 4.sp),
        SoftButton(
          label: action,
          background: AppColors.danger,
          foreground: AppColors.white,
          onPressed: () => Get.back<bool>(result: true),
        ),
        SizedBox(height: 10.sp),
        SoftButton(
          label: 'Cancel',
          background: k.card,
          onPressed: () => Get.back<bool>(result: false),
        ),
      ],
    );
  }
}
