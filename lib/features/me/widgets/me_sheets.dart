import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/backend/backend_service.dart';
import '../../../resources/images.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_widgets.dart';

enum ExportChoice { csv, json }

/// "How I eat" picker. Returns the diet id, or null when dismissed.
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

/// A cloud backup was found. Returns true to replace this phone's data with
/// it, false to keep this phone's data (it then becomes the cloud copy).
Future<bool?> showRestoreSheet({
  required String when,
  required bool phoneHasData,
}) {
  return Get.bottomSheet<bool>(
    _RestoreSheet(when: when, phoneHasData: phoneHasData),
    isScrollControlled: true,
  );
}

/// The account already has data. Returns true = use the saved data,
/// false = the other choice ([otherLabel]), null = closed.
Future<bool?> showWelcomeBackSheet({
  required CloudBackup backup,
  required String otherLabel,
  required String otherNote,
}) {
  return Get.bottomSheet<bool>(
    _WelcomeBackSheet(
      backup: backup,
      otherLabel: otherLabel,
      otherNote: otherNote,
    ),
    isScrollControlled: true,
  );
}

class _WelcomeBackSheet extends StatelessWidget {
  const _WelcomeBackSheet({
    required this.backup,
    required this.otherLabel,
    required this.otherNote,
  });

  final CloudBackup backup;
  final String otherLabel;
  final String otherNote;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.number(18.sp).copyWith(color: k.text)),
          Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: k.muted,
            ),
          ),
        ],
      ),
    );
    return KSheetFrame(
      icon: ThreeD(Img3d.great, size: 48.sp),
      title: 'Welcome back',
      sub: 'We found your Kindose data in this account.',
      children: [
        Semantics(
          label:
              '${backup.doses} doses, ${backup.weighIns} weigh-ins, last synced ${Dates.short(backup.updatedAt)}',
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: k.card,
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: Row(
              children: [
                stat('${backup.doses}', 'doses'),
                stat('${backup.weighIns}', 'weigh-ins'),
                stat(Dates.short(backup.updatedAt), 'last synced'),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.sp),
        PillButton(
          label: 'Use my saved data',
          ink: !dark,
          onPressed: () {
            Haptics.instance.mediumImpact();
            Navigator.of(context).pop(true);
          },
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: otherLabel,
          height: 50,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SizedBox(height: 8.sp),
        Text(
          otherNote,
          textAlign: TextAlign.center,
          style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
        ),
      ],
    );
  }
}

/// Last check before deleting the account. Returns true to delete.
Future<bool?> showDeleteAccountSheet() {
  return Get.bottomSheet<bool>(
    const _DeleteAccountSheet(),
    isScrollControlled: true,
  );
}

/// Last check before wiping the phone. Returns true to delete.
Future<bool?> showDeleteAllSheet({bool signedIn = false}) {
  return Get.bottomSheet<bool>(
    _DeleteSheet(signedIn: signedIn),
    isScrollControlled: true,
  );
}

/// Before signing out. [synced] false = the latest changes couldn't be
/// backed up. Returns true to sign out.
Future<bool?> showSignOutSheet({required bool synced, required String email}) {
  return Get.bottomSheet<bool>(
    _SignOutSheet(synced: synced, email: email),
    isScrollControlled: true,
  );
}

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet({required this.synced, required this.email});

  final bool synced;
  final String email;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      icon: KIconTile(
        icon: synced ? Icons.logout_rounded : Icons.cloud_off_rounded,
        bg: synced ? k.cardAlt : AppColors.dangerSoft,
        fg: synced ? k.text : AppColors.danger,
      ),
      title: 'Sign out?',
      sub: synced
          ? 'Everything is backed up to $email. Signing out removes it from '
                'this phone. Sign in again any time to get it back.'
          : "Your latest changes couldn't be backed up (no internet). If you "
                'sign out now, they are lost. Connect and try again, or sign out anyway.',
      children: [
        SoftButton(
          label: synced ? 'Sign out' : 'Sign out anyway',
          background: synced ? k.text : AppColors.danger,
          foreground: synced ? k.bg : AppColors.white,
          height: 50,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: 'Stay signed in',
          height: 50,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _DietSheet extends StatelessWidget {
  const _DietSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final options = [
      (
        'nonveg',
        'I eat everything',
        'Meat, fish, eggs and dairy',
        Img3d.chicken,
      ),
      ('pesc', 'Pescatarian', 'Fish and seafood, no meat', Img3d.fish),
      ('veg', 'Vegetarian', 'Eggs and dairy, no meat or fish', Img3d.egg),
      ('vegan', 'Vegan', 'No animal foods at all', Img3d.seedling),
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
  const _DeleteSheet({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return KSheetFrame(
      icon: const KIconTile(
        icon: Icons.delete_outline_rounded,
        bg: AppColors.dangerSoft,
        fg: AppColors.danger,
      ),
      title: 'Delete all my data?',
      sub: signedIn
          ? 'Every dose, weigh-in, check-in and setting is removed from this phone, '
                'and you are signed out. Your cloud backup stays until you delete your account.'
          : 'Every dose, weigh-in, check-in and setting is removed from this phone. '
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

class _RestoreSheet extends StatelessWidget {
  const _RestoreSheet({required this.when, required this.phoneHasData});

  final String when;
  final bool phoneHasData;

  @override
  Widget build(BuildContext context) {
    final dark = context.k.selectedBorder == AppColors.lime;
    return KSheetFrame(
      icon: ThreeD(Img3d.clipboard, size: 48.sp),
      title: 'Backup found',
      sub: phoneHasData
          ? 'Saved $when. Restoring replaces what is on this phone now. '
                'Keep this phone instead, and it becomes your backup.'
          : 'Saved $when. Bring your doses, weigh-ins and settings back to this phone. '
                'Start fresh replaces this backup with your new plan.',
      children: [
        PillButton(
          label: 'Restore my backup',
          ink: !dark,
          onPressed: () {
            Haptics.instance.mediumImpact();
            Navigator.of(context).pop(true);
          },
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: phoneHasData ? 'Keep this phone' : 'Start fresh',
          height: 48,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  @override
  Widget build(BuildContext context) {
    return KSheetFrame(
      icon: const KIconTile(
        icon: Icons.person_remove_outlined,
        bg: AppColors.dangerSoft,
        fg: AppColors.danger,
      ),
      title: 'Delete your account?',
      sub:
          'Your account, its cloud backup and everything on this phone are '
          'deleted for good. Export first if you want a copy. A Plus '
          'subscription is cancelled in your App Store or Google Play settings.',
      children: [
        SoftButton(
          label: 'Delete my account',
          background: AppColors.danger,
          foreground: AppColors.white,
          height: 50,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 8.sp),
        SoftButton(
          label: 'Keep my account',
          height: 50,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
