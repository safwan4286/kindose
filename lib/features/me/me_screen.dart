import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/plus/plus_access.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/drop_mark.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../home/home_screen.dart';
import 'me_controller.dart';

/// Me tab: plan, Plus, goals, reminders, units and theme, backup, your
/// data and about.
class MeScreen extends GetView<MeController> {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.watch();
        final c = controller;
        return ListView(
          padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, kNavClearance),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Me',
                style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
              ),
            ),
            SizedBox(height: 16.sp),
            _BackupCard(controller: c).enter(motion),
            SizedBox(height: 12.sp),
            _PlanCard(controller: c).enter(motion, delay: 30),
            SizedBox(height: 12.sp),
            _PlusCard(controller: c).enter(motion, delay: 60),
            if (kDebugMode) _DebugAccess(controller: c),
            _label(context, 'Treatment'),
            KGroup(
              children: [
                if (c.hasMedicine) ...[
                  _NavRow(
                    label: 'Medicine & dose',
                    value: c.medicineTitle,
                    onTap: c.editMedicine,
                  ),
                  _NavRow(
                    label: 'Schedule',
                    value: c.scheduleLabel,
                    onTap: c.editSchedule,
                  ),
                ],
                _NavRow(
                  label: c.pensLabel,
                  sub: 'What’s left, refills and spend',
                  value: c.pensValue,
                  plus: !c.isPlus,
                  onTap: c.openPens,
                ),
                if (!c.isTablet)
                  _NavRow(
                    label: 'Injection guide',
                    sub: 'A calm walk-through, step by step',
                    onTap: c.openGuide,
                  ),
              ],
            ).enter(motion, delay: 80),
            _label(context, 'Goals'),
            KGroup(
              children: [
                _NavRow(
                  label: 'Starting weight',
                  value: c.startWeightLabel,
                  onTap: () => c.editStartWeight(context),
                ),
                _NavRow(
                  label: 'Goal weight',
                  value: c.goalWeightLabel,
                  onTap: () => c.editGoalWeight(context),
                ),
                _NavRow(
                  label: 'Protein',
                  value: c.proteinLabel,
                  onTap: () => c.editProteinGoal(context),
                ),
                _NavRow(
                  label: 'Water',
                  value: c.waterLabel,
                  onTap: () => c.editWaterGoal(context),
                ),
                _NavRow(
                  label: 'How I eat',
                  value: c.dietLabel,
                  onTap: c.editDiet,
                ),
                _NavRow(
                  label: 'Help me with',
                  value: c.focusLabel,
                  onTap: c.editFocus,
                ),
              ],
            ).enter(motion, delay: 100),
            _label(context, 'About me'),
            KGroup(
              children: [
                _NavRow(
                  label: 'Treatment started',
                  value: c.treatmentStartLabel,
                  onTap: c.editTreatmentStart,
                ),
                _NavRow(
                  label: 'Height',
                  value: c.heightLabel,
                  onTap: c.editHeight,
                ),
                _NavRow(label: 'Sex', value: c.sexLabel, onTap: c.editSex),
                _NavRow(
                  label: 'Date of birth',
                  value: c.birthLabel,
                  onTap: c.editBirth,
                ),
                _NavRow(
                  label: 'Activity',
                  value: c.activityLabel,
                  onTap: c.editActivity,
                ),
              ],
            ).enter(motion, delay: 120),
            _label(context, 'App'),
            KGroup(
              padded: true,
              children: [
                _NavRow(
                  label: 'Notifications',
                  sub: c.notificationsSummary,
                  onTap: c.openNotifications,
                  inset: false,
                ),
                _SettingRow(
                  label: 'Weight',
                  child: SizedBox(
                    width: 140.sp,
                    child: KSegmented<bool>(
                      options: const [true, false],
                      selected: c.useKg,
                      onChanged: c.setUseKg,
                      labelOf: (v) => v ? 'kg' : 'lb',
                      dense: true,
                    ),
                  ),
                ),
                _SettingRow(
                  label: 'Height',
                  child: SizedBox(
                    width: 140.sp,
                    child: KSegmented<bool>(
                      options: const [true, false],
                      selected: c.heightInCm,
                      onChanged: c.setHeightInCm,
                      labelOf: (v) => v ? 'cm' : 'ft · in',
                      dense: true,
                    ),
                  ),
                ),
                _SettingRow(
                  label: 'Water',
                  child: SizedBox(
                    width: 140.sp,
                    child: KSegmented<bool>(
                      options: const [false, true],
                      selected: c.useOz,
                      onChanged: c.setUseOz,
                      labelOf: (v) => v ? 'fl oz' : 'L',
                      dense: true,
                    ),
                  ),
                ),
                _SettingRow(
                  label: 'Theme',
                  child: SizedBox(
                    width: 210.sp,
                    child: KSegmented<ThemeMode>(
                      options: const [
                        ThemeMode.system,
                        ThemeMode.light,
                        ThemeMode.dark,
                      ],
                      selected: c.themeMode,
                      onChanged: c.setTheme,
                      labelOf: (m) => switch (m) {
                        ThemeMode.system => 'System',
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark',
                      },
                      dense: true,
                    ),
                  ),
                ),
              ],
            ).enter(motion, delay: 170),
            _label(context, 'Your data'),
            KGroup(
              children: [
                _NavRow(
                  label: c.exporting.value ? 'Preparing…' : 'Export my data',
                  sub: 'Spreadsheet files for Excel or Google Sheets',
                  onTap: c.exporting.value ? null : c.export,
                ),
                // Signed in: deleting the account also erases the cloud
                // backup and this phone. Signed out: only the phone.
                if (c.signedIn)
                  _NavRow(
                    label: 'Delete my account',
                    sub: 'Erases your account and all your data',
                    danger: true,
                    onTap: c.deleteAccount,
                  )
                else
                  _NavRow(
                    label: 'Delete all my data',
                    sub: 'Erases everything on this phone',
                    danger: true,
                    onTap: c.confirmDeleteAll,
                  ),
              ],
            ),
            _label(context, 'About'),
            KGroup(
              children: [
                _NavRow(label: 'Privacy policy', onTap: c.openPrivacy),
                _NavRow(label: 'Terms of use', onTap: c.openTerms),
                _NavRow(label: 'Medical sources', onTap: c.openSources),
                _NavRow(label: 'Help & FAQ', onTap: c.openHelp),
                _NavRow(
                  label: 'Suggest a feature',
                  sub: 'Ideas and improvements, we read them all',
                  onTap: c.suggestFeature,
                ),
                if (c.canContact)
                  _NavRow(label: 'Contact support', onTap: c.contactSupport),
                if (c.canRate) _NavRow(label: 'Rate Kindose', onTap: c.rateApp),
              ],
            ),
            if (c.signedIn) ...[
              SizedBox(height: 24.sp),
              SoftButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                background: k.card,
                // Same red as the danger rows (lighter in dark mode).
                foreground: k.selectedBorder == AppColors.lime
                    ? const Color(0xFFFF8A80)
                    : AppColors.danger,
                height: 52,
                onPressed: c.backend.busy.value ? null : c.signOut,
              ),
            ],
            SizedBox(height: 18.sp),
            // Open-source licences (packages, icons, fonts) as a quiet link
            // on the version line rather than a menu row.
            Semantics(
              button: true,
              label: 'Open-source licences',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => c.openLicences(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.sp),
                  child: Text.rich(
                    TextSpan(
                      text: c.version.value.isEmpty
                          ? 'Kindose · '
                          : 'Kindose ${c.version.value} · ',
                      children: [
                        TextSpan(
                          text: 'Licences',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: k.faint,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: k.faint,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              "Kindose helps you keep track. It doesn't give medical advice.",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                fontSize: 12.sp,
                height: 1.5,
                color: k.faint,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppText.caps.copyWith(
          fontSize: 12.sp,
          letterSpacing: 1.1,
          color: context.k.faint,
        ),
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;

    Widget fact(String label, String value, String sub) => Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.sp),
        child: Column(
          children: [
            Text(
              label,
              style: AppText.caps.copyWith(
                fontSize: 10.5.sp,
                letterSpacing: 0.8,
                color: k.faint,
              ),
            ),
            SizedBox(height: 4.sp),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: k.text,
                ),
              ),
            ),
            if (sub.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  sub,
                  maxLines: 1,
                  style: AppText.small.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: k.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    Widget divider() => Container(width: 1, height: 44.sp, color: k.border);

    return Container(
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(24.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50.sp,
                height: 50.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(16.sp),
                ),
                child: Icon(
                  c.isTablet
                      ? PhosphorIconsBold.pill
                      : PhosphorIconsBold.syringe,
                  size: 24.sp,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.planCaption,
                      style: AppText.caps.copyWith(
                        fontSize: 11.5.sp,
                        letterSpacing: 1,
                        color: k.faint,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      c.medicineTitle,
                      maxLines: 2,
                      style: AppText.h2.copyWith(
                        fontSize: 21.sp,
                        letterSpacing: -0.4,
                        color: k.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          if (c.hasMedicine)
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.sp, horizontal: 6.sp),
              decoration: BoxDecoration(
                color: k.bg,
                borderRadius: BorderRadius.circular(16.sp),
              ),
              child: Row(
                children: [
                  fact('FORM', c.formLabel, c.formSub),
                  divider(),
                  fact('SCHEDULE', c.scheduleDay, c.scheduleTime),
                  divider(),
                  fact('NEXT DOSE', c.nextShort, c.nextSub),
                ],
              ),
            )
          else ...[
            Text(
              c.planSub,
              style: AppText.small.copyWith(fontSize: 13.5.sp, color: k.muted),
            ),
            SizedBox(height: 12.sp),
            PillButton(label: 'Add my medicine', onPressed: c.editPlan),
          ],
        ],
      ),
    );
  }
}

class _PlusCard extends StatelessWidget {
  const _PlusCard({required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final state = controller.planState;
    final ended = state == 'ended';
    final plus = state == 'plus';
    return PressScale(
      semanticLabel:
          '${controller.planTitle}. ${controller.planSub}. ${controller.planButton}',
      onTap: controller.openPlus,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: AppColors.hero,
            borderRadius: BorderRadius.circular(22.sp),
            border: ended
                ? Border.all(color: AppColors.lime, width: 2)
                : (k.selectedBorder == AppColors.lime
                      ? Border.all(color: k.border)
                      : null),
          ),
          child: Row(
            children: [
              if (ended)
                ThreeD(Img3d.locked, size: 40.sp)
              else
                DropMark(size: 40.sp),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.planTitle,
                      style: AppText.title.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      controller.planSub,
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.heroMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.sp),
              Container(
                height: 38.sp,
                padding: EdgeInsets.symmetric(horizontal: 14.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: plus ? Colors.transparent : AppColors.lime,
                  borderRadius: BorderRadius.circular(19.sp),
                  border: plus
                      ? Border.all(
                          color: AppColors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Text(
                  controller.planButton,
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: plus ? AppColors.white : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug builds only: jump between free-week states while testing.
class _DebugAccess extends StatelessWidget {
  const _DebugAccess({required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget chip(String label, Future<void> Function() onTap) => Padding(
      padding: EdgeInsets.only(right: 8.sp, bottom: 8.sp),
      child: PressScale(
        semanticLabel: label,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
          decoration: BoxDecoration(
            color: k.cardAlt,
            borderRadius: BorderRadius.circular(14.sp),
          ),
          child: Text(
            label,
            style: AppText.small.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: k.text,
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: 10.sp),
      child: Wrap(
        children: [
          chip('Debug: restart free week', controller.debugRestartWeek),
          chip('End free week', controller.debugEndWeek),
          chip('Real dates', controller.debugRealDates),
          chip(
            PlusAccess.debugPlus.value ? 'Plus: on ✓' : 'Plus: off',
            controller.debugTogglePlus,
          ),
          chip('Test reminders', controller.debugTestReminders),
          chip('Show planned', controller.debugShowPlanned),
          chip('Fill test data', controller.debugFillTestData),
          chip('Remove test data', controller.debugClearTestData),
          chip('Show offer', controller.debugShowOffer),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: controller.signedIn
          ? _SignedInBackup(key: const ValueKey('in'), controller: controller)
          : _SignedOutBackup(
              key: const ValueKey('out'),
              controller: controller,
            ),
    );
  }
}

class _SignedOutBackup extends StatelessWidget {
  const _SignedOutBackup({super.key, required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final accent = dark ? AppColors.amberSoft : AppColors.amberText;
    final busy = controller.backend.busy.value;
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: dark ? k.card : AppColors.amberWash,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smartphone_rounded, size: 22.sp, color: accent),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Only on this phone',
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      'If you lose or change your phone, your history goes with it. Back up free with your ${Platform.isIOS ? 'Apple or Google' : 'Google'} account.',
                      style: AppText.small.copyWith(
                        fontSize: 12.5.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          SoftButton(
            label: busy ? 'Signing in…' : 'Back up my data',
            background: dark ? AppColors.lime : AppColors.ink,
            foreground: dark ? AppColors.ink : AppColors.white,
            height: 46,
            onPressed: busy ? null : controller.backup,
          ),
        ],
      ),
    );
  }
}

class _SignedInBackup extends StatelessWidget {
  const _SignedInBackup({super.key, required this.controller});

  final MeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final busy = controller.backend.busy.value;
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Who is signed in.
          Semantics(
            label: '${controller.accountVia}: ${controller.accountEmail}',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  width: 36.sp,
                  height: 36.sp,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.lime : AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    controller.accountInitial,
                    style: AppText.title.copyWith(
                      fontSize: 16.sp,
                      color: dark ? AppColors.ink : AppColors.lime,
                    ),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.accountVia.toUpperCase(),
                        style: AppText.caps.copyWith(
                          fontSize: 10.5.sp,
                          letterSpacing: 0.9,
                          color: k.faint,
                        ),
                      ),
                      SizedBox(height: 1.sp),
                      Text(
                        controller.accountEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: k.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.sp),
            child: Divider(height: 1, thickness: 1, color: k.border),
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 10.sp,
                height: 10.sp,
                decoration: BoxDecoration(
                  color: controller.syncBlocked != null
                      ? (dark ? const Color(0xFFFF8A80) : AppColors.danger)
                      : controller.syncWaiting && !controller.syncSoon
                      ? const Color(0xFFF0B44C)
                      : const Color(0xFF5DBB63),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.backupLine,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: k.text,
                        ),
                      ),
                      SizedBox(height: 2.sp),
                      Text(
                        controller.backupSub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: k.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.syncWaiting && controller.syncBlocked == null) ...[
                SizedBox(width: 8.sp),
                SoftButton(
                  label: busy
                      ? 'Syncing…'
                      : (controller.syncSoon ? 'Sync now' : 'Retry'),
                  background: k.cardAlt,
                  height: 36,
                  onPressed: busy ? null : controller.backupNow,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// White rounded group with hairline dividers between rows.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.onTap,
    this.value,
    this.sub,
    this.danger = false,
    this.plus = false,
    this.inset = true,
  });

  final String label;
  final String? value;
  final String? sub;
  final bool danger;

  /// Shows the Plus tag before the arrow.
  final bool plus;
  final VoidCallback? onTap;

  /// Side padding of its own; off inside a padded group (KGroup.padded).
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final red = dark ? const Color(0xFFFF8A80) : AppColors.danger;
    final color = danger ? red : k.text;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: [
        label,
        ?value,
        ?sub,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.sp),
            padding: EdgeInsets.symmetric(
              horizontal: inset ? 16.sp : 0,
              vertical: 12.sp,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: color,
                        ),
                      ),
                      if (sub != null)
                        Text(
                          sub!,
                          style: AppText.small.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: k.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null) ...[
                  SizedBox(width: 8.sp),
                  // Capped, not Flexible, so the label keeps the free space
                  // and every value sits flush against the arrow.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 170.sp),
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppText.small.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: k.muted,
                      ),
                    ),
                  ),
                ],
                if (plus) ...[SizedBox(width: 8.sp), const PlusTag()],
                SizedBox(width: 6.sp),
                PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 16.sp,
                  color: danger ? color : k.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.sp),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.title.copyWith(
                fontSize: 15.sp,
                color: context.k.text,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
