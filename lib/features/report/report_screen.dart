import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_sheet.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../home/home_screen.dart';
import 'report_controller.dart';

/// Doctor report tab: appointment, period, what to include, questions,
/// optional name, then Preview (free) and Share PDF (Plus).
class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: Obx(() {
        controller.watch();
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, kNavClearance),
          children: [
            Text('DOCTOR REPORT', style: _caps(context)),
            SizedBox(height: 4.sp),
            Semantics(
              header: true,
              child: Text(
                'One page for your doctor',
                style: AppText.h1.copyWith(fontSize: 30.sp, color: k.text),
              ),
            ).enter(motion),
            SizedBox(height: 6.sp),
            Text(
              'Only what you logged. Nothing is sent anywhere unless you share it.',
              style: AppText.bodyStrong.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: k.muted,
              ),
            ),
            SizedBox(height: 16.sp),
            _AppointmentCard(controller: controller).enter(motion, delay: 40),
            _label(context, 'Period'),
            _PeriodRow(controller: controller).enter(motion, delay: 80),
            SizedBox(height: 14.sp),
            _PreviewCard(controller: controller).enter(motion, delay: 110),
            _label(context, 'What to include'),
            _Toggles(controller: controller).enter(motion, delay: 140),
            _label(context, 'Questions for your doctor'),
            _Questions(controller: controller).enter(motion, delay: 170),
            SizedBox(height: 12.sp),
            _NameCard(controller: controller),
            SizedBox(height: 18.sp),
            PillButton(
              label: controller.isPlus ? 'Share PDF' : 'Share PDF · Plus',
              icon: PhosphorIconsBold.shareNetwork,
              busy: controller.sharing.value,
              onPressed: controller.sharePdf,
            ),
            SizedBox(height: 8.sp),
            Text(
              controller.isPlus
                  ? 'Opens your share sheet: email, WhatsApp, print.'
                  : 'Preview is free. Show it on your phone at the visit.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontSize: 12.5.sp, color: k.muted),
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
      child: Text(text.toUpperCase(), style: _caps(context)),
    ),
  );
}

TextStyle _caps(BuildContext c) => AppText.caps.copyWith(
  fontSize: 12.sp,
  letterSpacing: 1.1,
  color: c.k.faint,
);

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final has = controller.nextAppointment != null;
    return PressScale(
      semanticLabel: has
          ? 'Next appointment ${controller.appointmentTitle}. Tap to change'
          : 'Add your next appointment',
      onTap: () => controller.pickAppointment(context),
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 14.sp, 14.sp),
          decoration: BoxDecoration(
            color: AppColors.hero,
            borderRadius: BorderRadius.circular(22.sp),
            border: k.selectedBorder == AppColors.lime
                ? Border.all(color: k.border)
                : null,
          ),
          child: Row(
            children: [
              ThreeD(Img3d.calendar, size: 40.sp),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT APPOINTMENT',
                      style: AppText.caps.copyWith(
                        fontSize: 11.5.sp,
                        letterSpacing: 0.8,
                        color: AppColors.lime,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      controller.appointmentTitle,
                      style: AppText.title.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      controller.appointmentSub,
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
                height: 36.sp,
                padding: EdgeInsets.symmetric(horizontal: 12.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.sp),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  has ? 'Change' : 'Add',
                  style: AppText.small.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
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

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final list = controller.periods;
    return Row(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) SizedBox(width: 6.sp),
          Expanded(
            child: ChoiceBox(
              selected: controller.period.value == list[i],
              height: 52.sp,
              radius: 16,
              padding: EdgeInsets.symmetric(horizontal: 4.sp),
              semanticLabel:
                  '${controller.periodLabel(list[i])} ${controller.periodSub(list[i])}',
              onTap: () => controller.pickPeriod(list[i]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.periodLabel(list[i]),
                    maxLines: 1,
                    style: AppText.small.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: k.text,
                    ),
                  ),
                  if (controller.periodSub(list[i]).isNotEmpty)
                    Text(
                      controller.periodSub(list[i]),
                      maxLines: 1,
                      style: AppText.tiny.copyWith(
                        fontSize: 11.sp,
                        color: k.faint,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget bar(double w, Color c, {double h = 3}) => Container(
      width: w,
      height: h,
      margin: EdgeInsets.only(top: 3.sp),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Container(
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 92.sp,
              height: 130.sp,
              padding: EdgeInsets.fromLTRB(7.sp, 8.sp, 7.sp, 8.sp),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6.sp),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.14),
                    blurRadius: 10.sp,
                    offset: Offset(0, 2.sp),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(46.sp, AppColors.ink, h: 5),
                  bar(62.sp, const Color(0xFFDCDAD2)),
                  SizedBox(height: 4.sp),
                  Row(
                    children: [
                      for (final c in [
                        AppColors.limeSoft,
                        const Color(0xFFF6F5F1),
                        const Color(0xFFF6F5F1),
                      ])
                        Expanded(
                          child: Container(
                            height: 14.sp,
                            margin: EdgeInsets.only(right: 3.sp),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: controller.weight.value ? 1 : 0.08,
                    child: Padding(
                      padding: EdgeInsets.only(top: 5.sp),
                      child: CustomPaint(
                        size: Size(78.sp, 22.sp),
                        painter: const _MiniLine(),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: controller.doses.value ? 1 : 0.08,
                    child: Column(
                      children: [
                        bar(78.sp, const Color(0xFFDCDAD2)),
                        bar(78.sp, const Color(0xFFDCDAD2)),
                        bar(54.sp, const Color(0xFFDCDAD2)),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: controller.sideEffects.value ? 1 : 0.08,
                    child: Row(
                      children: [
                        bar(30.sp, const Color(0xFFF7B895), h: 6),
                        SizedBox(width: 2.sp),
                        bar(18.sp, AppColors.tangerineSoft, h: 6),
                      ],
                    ),
                  ),
                  if (controller.questions.isNotEmpty) ...[
                    bar(40.sp, AppColors.ink),
                    bar(70.sp, const Color(0xFFDCDAD2)),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 14.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.periodTitle,
                  style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
                ),
                SizedBox(height: 4.sp),
                Text(
                  controller.summary,
                  style: AppText.small.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: k.muted,
                  ),
                ),
                SizedBox(height: 10.sp),
                SoftButton(
                  label: 'Preview',
                  height: 36,
                  outlined: true,
                  onPressed: controller.preview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLine extends CustomPainter {
  const _MiniLine();

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [0.1, 0.25, 0.4, 0.55, 0.7, 0.8, 0.9];
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = size.width * i / (pts.length - 1);
      final y = size.height * pts[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_MiniLine old) => false;
}

class _Toggles extends StatelessWidget {
  const _Toggles({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final rows = [
      (
        'Doses and injection spots',
        'Dates, dose, spot, how it felt',
        controller.doses,
      ),
      ('Weight chart', 'With dose changes marked', controller.weight),
      ('Side effects', 'How often and how strong', controller.sideEffects),
      (
        'Protein and water',
        'Daily averages and goal days',
        controller.nutrition,
      ),
      ('My notes', 'Off by default. They can be personal', controller.notes),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: k.border),
            SwitchRow(
              label: rows[i].$1,
              sub: rows[i].$2,
              value: rows[i].$3.value,
              onChanged: (_) => controller.flip(rows[i].$3),
              padding: EdgeInsets.symmetric(vertical: 10.sp),
            ),
          ],
        ],
      ),
    );
  }
}

class _Questions extends StatelessWidget {
  const _Questions({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final qs = controller.questions;
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < qs.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.sp, horizontal: 4.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22.sp,
                    height: 22.sp,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dark ? k.cardAlt : AppColors.limeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.tiny.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: dark ? k.text : AppColors.limeText,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Expanded(
                    child: Text(
                      qs[i],
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 14.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: PhosphorIconsBold.x,
                    label: 'Remove question ${i + 1}',
                    size: 32.sp,
                    background: k.bg,
                    onTap: () => controller.removeQuestion(i),
                  ),
                ],
              ),
            ),
          SizedBox(height: 4.sp),
          TextField(
            controller: controller.questionCtrl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: 160,
            onSubmitted: (_) => controller.addQuestion(),
            style: AppText.bodyStrong.copyWith(fontSize: 14.sp, color: k.text),
            decoration: InputDecoration(
              hintText: 'Write your own question',
              counterText: '',
              prefixIcon: Icon(
                PhosphorIconsBold.plus,
                size: 16.sp,
                color: k.muted,
              ),
              suffixIcon: IconButton(
                tooltip: 'Add question',
                icon: Icon(PhosphorIconsBold.check, size: 18.sp, color: k.text),
                onPressed: controller.addQuestion,
              ),
            ),
          ),
          if (controller.ideas.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            Text(
              'IDEAS',
              style: AppText.caps.copyWith(fontSize: 11.5.sp, color: k.faint),
            ),
            SizedBox(height: 6.sp),
            Wrap(
              spacing: 6.sp,
              runSpacing: 6.sp,
              children: [
                for (final idea in controller.ideas)
                  PressScale(
                    semanticLabel: 'Add question: $idea',
                    onTap: () => controller.addQuestion(idea),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.sp,
                        vertical: 8.sp,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.sp),
                        border: Border.all(color: k.border, width: 1.5),
                      ),
                      child: Text(
                        '+ $idea',
                        style: AppText.small.copyWith(
                          fontSize: 13.sp,
                          color: k.text,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        children: [
          SwitchRow(
            label: 'Add my name and birth date',
            sub:
                'Only printed on the PDF so the clinic can file it. Never saved or uploaded.',
            value: controller.includeName.value,
            onChanged: (_) => controller.flip(controller.includeName),
            padding: EdgeInsets.symmetric(vertical: 8.sp),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: !controller.includeName.value
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(bottom: 10.sp),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller.nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            hintText: 'Full name',
                          ),
                        ),
                        SizedBox(height: 8.sp),
                        TextField(
                          controller: controller.dobCtrl,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            hintText: 'Birth date, e.g. 12 Mar 1988',
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
