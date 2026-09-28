import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/colors.dart';
import '../../../resources/images.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/region/region.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_widgets.dart';

enum ExportChoice { csv, json }

/// "How I eat" picker. Returns the diet id, or null when dismissed.
/// Jain is offered in India, or when it is already the saved choice.
Future<String?> showDietSheet(String? current) {
  return Get.bottomSheet<String>(
    _DietSheet(current: current),
    isScrollControlled: true,
  );
}

/// Export format picker.
Future<ExportChoice?> showExportSheet() {
  return Get.bottomSheet<ExportChoice>(
    const _ExportSheet(),
    isScrollControlled: true,
  );
}

/// Explains that cloud backup is coming. Returns true to save a backup
/// file now.
Future<bool?> showBackupSoonSheet() {
  return Get.bottomSheet<bool>(const _BackupSheet(), isScrollControlled: true);
}

/// Last check before wiping the phone. Returns true to delete.
Future<bool?> showDeleteAllSheet() {
  return Get.bottomSheet<bool>(const _DeleteSheet(), isScrollControlled: true);
}

class _DietSheet extends StatelessWidget {
  const _DietSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final options = [
      ('veg', 'Vegetarian', 'Dairy, no meat, fish or eggs', Img3d.paneer),
      ('egg', 'Eggetarian', 'Vegetarian plus eggs', Img3d.egg),
      (
        'nonveg',
        'Non-vegetarian',
        'Eggs, chicken, fish and meat',
        Img3d.chicken,
      ),
      ('vegan', 'Vegan', 'No animal foods, including dairy', Img3d.seedling),
      if (Region.isIndia || current == 'jain')
        ('jain', 'Jain', 'No root vegetables, onion or garlic', Img3d.dal),
    ];
    return KSheetFrame(
      title: 'How do you eat?',
      sub: 'Protein ideas will match what you eat.',
      children: [
        for (final o in options) ...[
          ChoiceBox(
            selected: o.$1 == current,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
            semanticLabel: '${o.$2}. ${o.$3}',
            onTap: () {
              Haptics.instance.selectionClick();
              Navigator.of(context).pop(o.$1);
            },
            child: Row(
              children: [
                ThreeD(o.$4, size: 32.sp),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.$2,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: k.text,
                        ),
                      ),
                      Text(
                        o.$3,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          color: k.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.sp),
        ],
      ],
    );
  }
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget option(ExportChoice c, String title, String sub, String icon) =>
        Padding(
          padding: EdgeInsets.only(bottom: 8.sp),
          child: ChoiceBox(
            selected: false,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
            semanticLabel: '$title. $sub',
            onTap: () => Navigator.of(context).pop(c),
            child: Row(
              children: [
                ThreeD(icon, size: 34.sp),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: k.text,
                        ),
                      ),
                      Text(
                        sub,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          color: k.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return KSheetFrame(
      title: 'Export everything',
      sub:
          'Your doses, weights, food, water and check-ins. Saved or sent only where you choose.',
      children: [
        option(
          ExportChoice.csv,
          'Spreadsheet (CSV)',
          'Three files you can open in Excel or Google Sheets',
          Img3d.clipboard,
        ),
        option(
          ExportChoice.json,
          'Backup file (JSON)',
          'One complete file. Keep it somewhere safe',
          Img3d.locked,
        ),
      ],
    );
  }
}

class _BackupSheet extends StatelessWidget {
  const _BackupSheet();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    return KSheetFrame(
      icon: ThreeD(Img3d.locked, size: 48.sp),
      title: 'Backup is almost here',
      sub:
          'Soon you can sign in with Google or Apple and your log will be backed up for free. '
          'Until then, save a backup file and keep it in Drive, iCloud or email.',
      children: [
        PillButton(
          label: 'Save a backup file',
          ink: !dark,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: 'Not now',
          height: 48,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet();

  @override
  Widget build(BuildContext context) {
    return KSheetFrame(
      icon: const KIconTile(
        icon: Icons.delete_outline_rounded,
        bg: AppColors.dangerSoft,
        fg: AppColors.danger,
      ),
      title: 'Delete all my data?',
      sub:
          'Every dose, weigh-in, check-in and setting is removed from this phone. '
          'This cannot be undone. Export first if you want a copy.',
      children: [
        SoftButton(
          label: 'Delete everything',
          background: AppColors.danger,
          foreground: AppColors.white,
          height: 50,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: 'Keep my data',
          height: 50,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
