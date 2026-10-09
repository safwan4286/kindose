import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_text_field.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/toast.dart';
import '../intake_controller.dart';

/// Tap on a food row: ½, 1, 1½, 2 or 3 servings, then add.
Future<void> showPortionSheet(Food food) {
  return Get.bottomSheet<void>(
    _PortionSheet(food: food),
    isScrollControlled: true,
  );
}

/// "+ Custom" (add grams, optionally save as a food) or editing a saved food.
Future<void> showCustomFoodSheet() {
  return Get.bottomSheet<void>(const _CustomSheet(), isScrollControlled: true);
}

TextStyle _caps(BuildContext c) => AppText.caps.copyWith(
  fontSize: 12.sp,
  letterSpacing: 1.1,
  color: c.k.muted,
);

class _PortionSheet extends GetView<IntakeController> {
  const _PortionSheet({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final one = food.portion.isEmpty ? '1 serving' : food.portion;
    return KSheetFrame(
      title: food.name,
      sub: '1 portion = $one · ${food.grams} g protein',
      icon: Container(
        width: 52.sp,
        height: 52.sp,
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(16.sp),
        ),
        alignment: Alignment.center,
        child: ThreeD(food.icon, size: 34.sp),
      ),
      children: [
        Text('HOW MUCH?', style: _caps(context)),
        SizedBox(height: 8.sp),
        Obx(() {
          final times = controller.portion.value;
          return Row(
            children: [
              for (final (i, p) in IntakeController.portions.indexed) ...[
                if (i > 0) SizedBox(width: 8.sp),
                Expanded(
                  child: ChoiceBox(
                    selected: p.times == times,
                    height: 48.sp,
                    radius: 14,
                    semanticLabel: '${p.label} portion',
                    onTap: () => controller.pickPortion(p.times),
                    child: Text(
                      p.label,
                      style: AppText.title.copyWith(
                        fontSize: 16.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        SizedBox(height: 18.sp),
        Obx(() {
          final g = controller.gramsFor(food, controller.portion.value);
          return Semantics(
            liveRegion: true,
            label: '$g grams protein',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: g.toDouble()),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) =>
                      NumberUnit('${v.round()}', 'g', size: 44.sp, color: k.text),
                ),
                SizedBox(width: 6.sp),
                Text(
                  'protein',
                  style: AppText.title.copyWith(
                    fontSize: 15.sp,
                    color: k.muted,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 16.sp),
        SoftButton(
          label: controller.isToday
              ? 'Add to today'
              : 'Add to ${controller.dayTitle.toLowerCase()}',
          background: k.text,
          foreground: k.bg,
          onPressed: () {
            final times = controller.portion.value;
            Navigator.of(context).pop();
            controller.addFood(food, times);
          },
        ),
      ],
    );
  }
}

class _CustomSheet extends GetView<IntakeController> {
  const _CustomSheet();

  static const List<int> _quick = [10, 15, 20, 25, 30];

  void _submit(BuildContext context) {
    final problem = controller.customProblem;
    if (problem != null) {
      showToast(problem);
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
    controller.submitCustom();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final editing = controller.editing;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: KSheetFrame(
        title: editing ? 'Edit food' : 'Add your own',
        sub: editing
            ? 'Changes apply next time you add it.'
            : 'Check the label for "Protein".',
        children: [
          Obx(() {
            final g = controller.customGrams.value;
            return Row(
              children: [
                CircleIconButton(
                  icon: PhosphorIconsBold.minus,
                  label: '1 gram less',
                  size: 52,
                  background: k.card,
                  onTap: g <= 1 ? null : () => controller.stepCustom(-1),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '$g grams protein. Tap to type',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.typeCustom(context),
                      child: Text(
                        '$g g',
                        textAlign: TextAlign.center,
                        style: AppText.number(44.sp).copyWith(color: k.text),
                      ),
                    ),
                  ),
                ),
                CircleIconButton(
                  icon: PhosphorIconsBold.plus,
                  label: '1 gram more',
                  size: 52,
                  background: k.card,
                  onTap: g >= 200 ? null : () => controller.stepCustom(1),
                ),
              ],
            );
          }),
          SizedBox(height: 10.sp),
          Obx(() {
            final g = controller.customGrams.value;
            return Row(
              children: [
                for (final (i, q) in _quick.indexed) ...[
                  if (i > 0) SizedBox(width: 6.sp),
                  Expanded(
                    child: ChoiceBox(
                      selected: q == g,
                      height: 38.sp,
                      radius: 12,
                      padding: EdgeInsets.zero,
                      semanticLabel: '$q grams',
                      onTap: () => controller.setCustom(q),
                      child: Text(
                        '$q',
                        style: AppText.title.copyWith(
                          fontSize: 14.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
          SizedBox(height: 16.sp),
          KTextField(
            controller: controller.nameCtrl,
            hint: editing ? 'Name' : 'Name (optional), e.g. Chobani yogurt',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 40,
          ),
          SizedBox(height: 8.sp),
          KTextField(
            controller: controller.portionCtrl,
            hint: 'Portion (optional), e.g. 1 cup',
            maxLength: 30,
            onSubmitted: (_) => _submit(context),
          ),
          if (!editing) ...[
            SizedBox(height: 8.sp),
            Obx(
              () => SwitchRow(
                label: 'Save to My foods',
                sub: 'Saved when it has a name. Add it again with one tap.',
                value: controller.saveCustom.value,
                onChanged: (_) => controller.toggleSaveCustom(),
              ),
            ),
            SizedBox(height: 8.sp),
            const _SnapSoon(),
          ],
          SizedBox(height: 16.sp),
          Obx(
            () => SoftButton(
              label: editing
                  ? 'Save changes'
                  : 'Add ${controller.customGrams.value} g',
              background: k.text,
              foreground: k.bg,
              onPressed: () => _submit(context),
            ),
          ),
          if (editing) ...[
            SizedBox(height: 8.sp),
            Center(
              child: LinkButton(
                label: 'Delete this food',
                color: AppColors.danger,
                onTap: () {
                  Navigator.of(context).pop();
                  controller.deleteEditing();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for the photo estimate that comes with AI later.
class _SnapSoon extends StatelessWidget {
  const _SnapSoon();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      label: 'Snap your plate. Coming soon',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.sp),
          border: Border.all(color: k.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsBold.camera, size: 18.sp, color: k.muted),
            SizedBox(width: 10.sp),
            Expanded(
              child: Text(
                'Snap your plate',
                style: AppText.small.copyWith(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: k.muted,
                ),
              ),
            ),
            KTag('SOON', bg: k.cardAlt, fg: k.textSoft),
          ],
        ),
      ),
    );
  }
}
