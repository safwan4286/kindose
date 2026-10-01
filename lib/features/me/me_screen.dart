import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
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
            _PlanCard(controller: c).enter(motion),
            SizedBox(height: 12.sp),
            _PlusCard(controller: c).enter(motion, delay: 60),
            if (kDebugMode) _DebugAccess(controller: c),
            _label(context, 'Treatment'),
            _Group(
              children: [
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
            _Group(
              children: [
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
              ],
            ).enter(motion, delay: 100),
            _label(context, 'Reminders'),
            _Group(
              padded: true,
              children: [
                SwitchRow(
                  label: 'Dose reminders',
                  sub: 'Dose day, and a follow-up if not logged',
                  value: c.doseReminders,
                  onChanged: c.setDoseReminders,
                  padding: EdgeInsets.symmetric(vertical: 12.sp),
                ),
                SwitchRow(
                  label: 'Doctor visit',
                  sub: '3 days before, to get your report ready',
                  value: c.visitReminders,
                  onChanged: c.setVisitReminders,
                  padding: EdgeInsets.symmetric(vertical: 12.sp),
                ),
                _PlusSwitchRow(
                  label: 'Protein & water nudges',
                  sub: 'Gentle nudges at lunch and afternoon',
                  onTap: c.foodNudges,
                ),
              ],
            ).enter(motion, delay: 140),
            _label(context, 'App'),
            _Group(
              padded: true,
              children: [
                _SettingRow(
                  label: 'Units',
                  child: SizedBox(
                    width: 120.sp,
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
            _label(context, c.signedIn ? 'Account & backup' : 'Backup'),
            _BackupCard(controller: c).enter(motion, delay: 200),
            _label(context, 'Your data'),
            _Group(
              children: [
                _NavRow(
                  label: c.exporting.value ? 'Preparing…' : 'Export everything',
                  sub: 'Spreadsheet (CSV) or a full backup file',
                  onTap: c.exporting.value ? null : c.export,
                ),
                if (c.signedIn)
                  _NavRow(
                    label: 'Delete my account',
                    sub: 'Removes your account and cloud backup',
                    danger: true,
                    onTap: c.deleteAccount,
                  ),
                _NavRow(
                  label: 'Delete all my data',
                  danger: true,
                  onTap: c.confirmDeleteAll,
                ),
              ],
            ),
            _label(context, 'About'),
            _Group(
              children: [
                _NavRow(label: 'Privacy policy', onTap: c.openLegal),
                _NavRow(label: 'Terms of use', onTap: c.openLegal),
                if (c.canContact)
                  _NavRow(label: 'Contact support', onTap: c.contactSupport),
                if (c.canRate) _NavRow(label: 'Rate Kindose', onTap: c.rateApp),
                _NavRow(
                  label: 'Licences',
                  onTap: () => c.openLicences(context),
                ),
              ],
            ),
            SizedBox(height: 18.sp),
            Text(
              '${c.version.value.isEmpty ? 'Kindose' : 'Kindose ${c.version.value}'}\n'
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
                      c.planTitle,
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
              if (c.hasMedicine) ...[
                SizedBox(width: 8.sp),
                CircleIconButton(
                  icon: PhosphorIconsBold.pencilSimple,
                  label: 'Edit plan',
                  size: 40.sp,
                  background: k.cardAlt,
                  onTap: c.editPlan,
                ),
              ],
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
      semanticLabel: '${controller.planTitle}. ${controller.planSub}. ${controller.planButton}',
      onTap: controller.openPlus,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: AppColors.hero,
            borderRadius: BorderRadius.circular(22.sp),
            border: ended
                ? Border.all(color: AppColors.lime, width: 2)
                : (k.selectedBorder == AppColors.lime ? Border.all(color: k.border) : null),
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
            style: AppText.small.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: k.text),
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
                      'If you lose or change your phone, your history goes with it. Back up free with Google.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.sp,
                height: 36.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.lime.withValues(alpha: 0.16)
                      : AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  size: 20.sp,
                  color: dark ? AppColors.lime : AppColors.limeText,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        controller.backupLine,
                        style: AppText.title.copyWith(
                          fontSize: 15.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      'Backs up by itself after changes',
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
            ],
          ),
          SizedBox(height: 12.sp),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: busy ? 'Backing up…' : 'Back up now',
                  background: dark ? AppColors.lime : AppColors.ink,
                  foreground: dark ? AppColors.ink : AppColors.white,
                  height: 46,
                  onPressed: busy ? null : controller.backupNow,
                ),
              ),
              SizedBox(width: 8.sp),
              SoftButton(
                label: 'Restore',
                background: k.cardAlt,
                height: 46,
                onPressed: busy ? null : controller.restoreBackup,
              ),
            ],
          ),
          SizedBox(height: 4.sp),
          Center(
            child: LinkButton(
              label: 'Sign out',
              onTap: busy ? null : controller.signOut,
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded group with hairline dividers between rows.
class _Group extends StatelessWidget {
  const _Group({required this.children, this.padded = false});

  final List<Widget> children;

  /// Adds side padding for rows that have none of their own (switches).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.sp),
      child: ColoredBox(
        color: k.card,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padded ? 16.sp : 0),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: k.border,
                    indent: padded ? 0 : 16.sp,
                    endIndent: padded ? 0 : 16.sp,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.onTap,
    this.value,
    this.sub,
    this.danger = false,
    this.plus = false,
  });

  final String label;
  final String? value;
  final String? sub;
  final bool danger;

  /// Shows the Plus tag before the arrow.
  final bool plus;
  final VoidCallback? onTap;

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
        if (value != null) value!,
        if (sub != null) sub!,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.sp),
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
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
                  Flexible(
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// A switch row for a Plus feature: shows the Plus tag and an off switch.
/// Tapping opens the Plus screen for free users.
class _PlusSwitchRow extends StatelessWidget {
  const _PlusSwitchRow({
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: '$label, Plus feature. $sub',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.sp),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.sp),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.sp,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppText.title.copyWith(
                            fontSize: 15.sp,
                            color: k.text,
                          ),
                        ),
                        const PlusTag(),
                      ],
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
              SizedBox(width: 12.sp),
              const KSwitch(value: false),
            ],
          ),
        ),
      ),
    );
  }
}
