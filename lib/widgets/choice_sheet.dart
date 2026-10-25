import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'k_sheet.dart';

/// A sheet listing [options]; the current one has a tick. Returns the
/// picked option, or null when dismissed.
Future<T?> showChoiceSheet<T>({
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
  String? sub,
}) {
  Haptics.instance.selectionClick();
  return Get.bottomSheet<T>(
    ChoiceSheet<T>(
      title: title,
      sub: sub,
      options: options,
      selected: selected,
      labelOf: labelOf,
    ),
    isScrollControlled: true,
  );
}

class ChoiceSheet<T> extends StatelessWidget {
  const ChoiceSheet({
    super.key,
    this.sub,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
  });

  final String title;
  final String? sub;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      title: title,
      sub: sub,
      children: [
        for (final o in options) ...[
          ChoiceBox(
            selected: o == selected,
            alignment: Alignment.centerLeft,
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
            semanticLabel: labelOf(o),
            onTap: () {
              Haptics.instance.selectionClick();
              Navigator.of(context).pop(o);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelOf(o),
                    style: AppText.title.copyWith(
                      fontSize: 15.sp,
                      color: k.text,
                    ),
                  ),
                ),
                if (o == selected)
                  Icon(PhosphorIconsBold.check, size: 18.sp, color: k.text),
              ],
            ),
          ),
          SizedBox(height: 8.sp),
        ],
      ],
    );
  }
}
