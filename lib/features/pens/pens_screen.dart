import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/supply/supply_service.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'pens_controller.dart';
import 'widgets/pens_sheets.dart';

/// Pens & cost (Plus): what's left in the current pen, spare pens at
/// home, a refill reminder and what the user spends.
class PensScreen extends GetView<PensController> {
  const PensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: k.bg,
      body: KSafeArea(
        child: Obx(() {
          controller.watch();
          final c = controller;
          return ListView(
            padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 28.sp),
            children: [
              Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  const PlusTag(),
                  const Spacer(),
                  if (c.unlocked && c.supply.isSetUp)
                    CircleIconButton(
                      icon: PhosphorIconsBold.slidersHorizontal,
                      label: 'Settings',
                      onTap: c.openSettings,
                    ),
                ],
              ),
              SizedBox(height: 14.sp),
              Semantics(
                header: true,
                child: Text(
                  c.title,
                  style: AppText.h1.copyWith(
                    fontSize: 30.sp,
                    height: 1.08,
                    color: k.text,
                  ),
                ),
              ),
              SizedBox(height: 6.sp),
              Text(
                'Counts down by itself each time you log a ${c.doseWord}.',
                style: AppText.bodyText.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: k.muted,
                ),
              ),
              SizedBox(height: 16.sp),
              if (!c.unlocked)
                _Locked(controller: c).enter(motion)
              else ...[
                _CurrentPack(controller: c).enter(motion),
                _cap(context, 'Supply at home'),
                _SpareCard(controller: c).enter(motion, delay: 60),
                SizedBox(height: 10.sp),
                _Card(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 6.sp,
                  ),
                  child: SwitchRow(
                    label: 'Refill reminder',
                    sub: c.refillSub,
                    value: c.supply.refillReminder.value,
                    onChanged: c.setRefillReminder,
                    padding: EdgeInsets.symmetric(vertical: 8.sp),
                  ),
                ).enter(motion, delay: 100),
                _cap(context, 'Spend'),
                _SpendCard(controller: c).enter(motion, delay: 140),
                _PurchasesHeader(onAdd: c.addPurchase),
                _Purchases(controller: c).enter(motion, delay: 180),
                SizedBox(height: 14.sp),
                Text(
                  'Only for your own records. Kindose doesn’t sell or order medicine.',
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: k.faint,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

Widget _cap(BuildContext context, String text) => Padding(
  padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp),
  child: SectionLabel(text, color: context.k.faint),
);

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: context.k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------ current pen

class _CurrentPack extends StatelessWidget {
  const _CurrentPack({required this.controller});

  final PensController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = c.supply;
    final setUp = s.isSetUp;
    final muted = AppColors.heroMuted;
    return Container(
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(24.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CURRENT ${c.pack.toUpperCase()}',
                style: AppText.caps.copyWith(fontSize: 12.sp, color: muted),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Text(
                  c.medicineLine,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.sp),
          if (!setUp) ...[
            Text(
              'Set up your ${c.pack}',
              style: AppText.h1.copyWith(
                fontSize: 26.sp,
                height: 1.1,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              'Tell us how many ${c.dosesWord} it holds and how many are left. We’ll count down from there.',
              style: AppText.bodyText.copyWith(fontSize: 14.sp, color: muted),
            ),
            SizedBox(height: 14.sp),
            PillButton(label: 'Set up', lime: true, onPressed: c.setUp),
          ] else ...[
            Row(
              children: [
                _DoseMeter(total: s.dosesPerPack.value, left: s.leftInPack),
                SizedBox(width: 16.sp),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.leftLine,
                          style: AppText.number(
                            34.sp,
                          ).copyWith(color: AppColors.white, height: 1),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          c.ofLine,
                          style: AppText.small.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.sp),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey<String>(c.refillLine),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.sp,
                  vertical: 10.sp,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.sp),
                ),
                child: Text(
                  c.refillLine,
                  style: AppText.small.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lime,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.sp),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: 'Start a new ${c.pack}',
                    onPressed: c.startNewPack,
                    background: c.newPackFirst
                        ? AppColors.lime
                        : AppColors.white.withValues(alpha: 0.1),
                    foreground: c.newPackFirst
                        ? AppColors.ink
                        : AppColors.white,
                    height: 46,
                  ),
                ),
                SizedBox(width: 8.sp),
                _OutlinePill(
                  label: 'Fix count',
                  onTap: () => c.fixCount(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One block per dose for pens (up to 8), a bar for bigger packs.
class _DoseMeter extends StatelessWidget {
  const _DoseMeter({required this.total, required this.left});

  final int total;
  final int left;

  @override
  Widget build(BuildContext context) {
    final used = total - left;
    final empty = AppColors.white.withValues(alpha: 0.08);
    final emptyEdge = AppColors.white.withValues(alpha: 0.12);
    const duration = Duration(milliseconds: 350);
    if (total > 8) {
      final h = 64.sp;
      return Container(
        width: 30.sp,
        height: h,
        decoration: BoxDecoration(
          color: empty,
          borderRadius: BorderRadius.circular(10.sp),
          border: Border.all(color: emptyEdge, width: 2),
        ),
        alignment: Alignment.bottomCenter,
        child: AnimatedFractionallySizedBox(
          duration: duration,
          curve: Curves.easeOutCubic,
          heightFactor: total == 0 ? 0 : left / total,
          widthFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(8.sp),
            ),
          ),
        ),
      );
    }
    final w = math.min(30.sp, (150.sp - 6.sp * (total - 1)) / total);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: 6.sp),
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: w,
              height: 64.sp,
              decoration: BoxDecoration(
                color: i < used ? empty : AppColors.lime,
                borderRadius: BorderRadius.circular(10.sp),
                border: Border.all(
                  color: i < used ? emptyEdge : AppColors.lime,
                  width: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 46.sp,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23.sp),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppText.button.copyWith(
            fontSize: 15.sp,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ spare

class _SpareCard extends StatelessWidget {
  const _SpareCard({required this.controller});

  final PensController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final n = c.supply.spareLeft;
    return _Card(
      child: Row(
        children: [
          Container(
            width: 48.sp,
            height: 48.sp,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.limeSoft,
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Text(
                '$n',
                key: ValueKey<int>(n),
                style: AppText.number(22.sp).copyWith(color: AppColors.ink),
              ),
            ),
          ),
          SizedBox(width: 14.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.spareTitle,
                  style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
                ),
                Text(
                  c.spareSub,
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.sp),
          StepButtons(
            value: n,
            onMinus: n > 0 ? () => c.changeSpare(-1) : null,
            onPlus: n < 99 ? () => c.changeSpare(1) : null,
            showValue: false,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ spend

class _SpendCard extends StatelessWidget {
  const _SpendCard({required this.controller});

  final PensController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final dark = k.selectedBorder == AppColors.lime;
    final months = c.months;
    final top = months.fold<double>(0, (a, m) => math.max(a, m.$2));
    final barMax = 74.sp;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    c.thisMonth,
                    style: AppText.number(30.sp).copyWith(color: k.text),
                  ),
                ),
              ),
              Text(
                c.monthName,
                style: AppText.small.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: k.muted,
                ),
              ),
            ],
          ),
          Text(
            c.spendSub,
            style: AppText.small.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: k.muted,
            ),
          ),
          SizedBox(height: 14.sp),
          SizedBox(
            height: barMax + 20.sp,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, m) in months.indexed) ...[
                  if (i > 0) SizedBox(width: 8.sp),
                  Expanded(
                    child: Semantics(
                      label: '${m.$1}: ${c.supply.money(m.$2)}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: top == 0 ? 0 : m.$2 / top,
                            ),
                            duration: Duration(milliseconds: 500 + i * 80),
                            curve: Curves.easeOutCubic,
                            builder: (_, f, _) => Container(
                              height: math.max(6.sp, barMax * f),
                              decoration: BoxDecoration(
                                color: m.$3
                                    ? (dark ? AppColors.lime : AppColors.ink)
                                    : k.border,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8.sp),
                                  bottom: Radius.circular(4.sp),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.sp),
                          SizedBox(
                            height: 14.sp,
                            child: FittedBox(
                              child: Text(
                                m.$1,
                                style: AppText.tiny.copyWith(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: k.faint,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- purchases

class _PurchasesHeader extends StatelessWidget {
  const _PurchasesHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.only(top: 12.sp, bottom: 0),
      child: Row(
        children: [
          Expanded(child: SectionLabel('Purchases', color: k.faint)),
          PressScale(
            onTap: onAdd,
            semanticLabel: 'Add a purchase',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 12.sp),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsBold.plus,
                    size: 14.sp,
                    color: k.text,
                  ),
                  SizedBox(width: 4.sp),
                  Text(
                    'Add',
                    style: AppText.caps.copyWith(
                      fontSize: 12.5.sp,
                      color: k.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Purchases extends StatelessWidget {
  const _Purchases({required this.controller});

  final PensController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    final list = c.supply.purchases;
    if (list.isEmpty) {
      return _Card(
        child: Column(
          children: [
            Text(
              'No purchases yet',
              style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
            ),
            SizedBox(height: 4.sp),
            Text(
              'Add what you paid to see your monthly spend and cost per ${c.doseWord}.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontSize: 13.sp, color: k.muted),
            ),
            SizedBox(height: 12.sp),
            SoftButton(
              label: 'Add a purchase',
              icon: PhosphorIconsBold.plus,
              onPressed: c.addPurchase,
              background: k.cardAlt,
              height: 46,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22.sp),
          child: ColoredBox(
            color: k.card,
            child: Column(
              children: [
                for (final (i, p) in list.indexed)
                  Dismissible(
                    key: ValueKey<String>(p.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => c.removePurchase(p),
                    background: Container(
                      color: AppColors.dangerSoft,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.sp),
                      child: PhosphorIcon(
                        PhosphorIconsBold.trash,
                        size: 20.sp,
                        color: AppColors.danger,
                      ),
                    ),
                    child: _PurchaseRow(
                      controller: c,
                      purchase: p,
                      divider: i > 0,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          'Swipe left to remove',
          style: AppText.small.copyWith(fontSize: 12.sp, color: k.faint),
        ),
      ],
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({
    required this.controller,
    required this.purchase,
    required this.divider,
  });

  final PensController controller;
  final Purchase purchase;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = controller;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 13.sp),
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: k.border.withValues(alpha: 0.6)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.purchaseTitle(purchase),
                  style: AppText.title.copyWith(
                    fontSize: 14.5.sp,
                    color: k.text,
                  ),
                ),
                Text(
                  c.purchaseSub(purchase),
                  maxLines: 1,
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
          SizedBox(width: 10.sp),
          Text(
            c.supply.money(purchase.price),
            style: AppText.title.copyWith(fontSize: 14.5.sp, color: k.text),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- locked

class _Locked extends StatelessWidget {
  const _Locked({required this.controller});

  final PensController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return _Card(
      padding: EdgeInsets.all(20.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.sp,
            height: 48.sp,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.limeSoft,
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: PhosphorIcon(
              PhosphorIconsBold.lockSimple,
              size: 22.sp,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 12.sp),
          Text(
            'Part of Kindose Plus',
            style: AppText.h2.copyWith(fontSize: 20.sp, color: k.text),
          ),
          SizedBox(height: 6.sp),
          Text(
            'Know how many ${controller.dosesWord} are left, get a refill reminder before you run out, and see what you spend.',
            style: AppText.bodyText.copyWith(fontSize: 14.sp, color: k.muted),
          ),
          SizedBox(height: 16.sp),
          PillButton(label: 'See Plus', onPressed: controller.openPlus),
        ],
      ),
    );
  }
}
