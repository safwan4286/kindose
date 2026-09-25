import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../home/home_screen.dart';
import 'report_controller.dart';

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, kNavClearance),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Doctor report', style: AppText.h1)),
                    const SizedBox(height: 2),
                    Text('One page, ready for your visit', style: AppText.bodyStrong.copyWith(color: k.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Floaty(child: ThreeD(Img3d.clipboard, size: 56)),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() => KCard(
                color: AppColors.hero,
                radius: 24,
                onTap: () => controller.pickAppointment(context),
                semanticLabel: 'Next appointment: ${controller.appointmentLabel}. Tap to change',
                child: Row(
                  children: [
                    const ThreeD(Img3d.stethoscope, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT APPOINTMENT', style: AppText.caps.copyWith(color: AppColors.heroMuted)),
                          const SizedBox(height: 2),
                          Text(controller.appointmentLabel, style: AppText.h2.copyWith(fontSize: 22, color: AppColors.lime)),
                        ],
                      ),
                    ),
                    const PhosphorIcon(PhosphorIconsDuotone.calendarBlank, color: AppColors.heroMuted, size: 22),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Obx(() => KCard(
                radius: 22,
                onTap: () => controller.pickRange(context),
                semanticLabel: 'Report period ${controller.rangeLabel}. Tap to change',
                child: Row(
                  children: [
                    const ThreeD(Img3d.calendar, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Period', style: AppText.title)),
                    Text(controller.rangeLabel, style: AppText.title.copyWith(color: AppColors.violet)),
                    const SizedBox(width: 4),
                    PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: k.faint),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          KCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PaperThumb(),
                const SizedBox(width: 14),
                Expanded(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Include', style: AppText.title),
                          const SizedBox(height: 4),
                          _Toggle('Doses & timing', controller.doses),
                          _Toggle('Weight', controller.weight),
                          _Toggle('Side effects', controller.sideEffects),
                          _Toggle('Protein & water', controller.nutrition),
                          _Toggle('My notes', controller.notes),
                        ],
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => KCard(
                radius: 22,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Column(
                  children: [
                    SwitchRow(
                      leading: const ThreeD(Img3d.locked, size: 32),
                      label: 'Add my name & birth date',
                      sub: 'Printed on the PDF only, never saved',
                      value: controller.includeName.value,
                      onChanged: (v) => controller.includeName.value = v,
                    ),
                    if (controller.includeName.value) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(hintText: 'Full name', fillColor: k.cardAlt),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.dobCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(hintText: 'Birth date, e.g. 14 Mar 1990', fillColor: k.cardAlt),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SoftButton(label: 'Preview', outlined: true, onPressed: controller.preview),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => SoftButton(
                      label: controller.sharing.value ? 'Preparing…' : 'Share PDF',
                      icon: PhosphorIconsBold.shareNetwork,
                      background: AppColors.violet,
                      foreground: AppColors.white,
                      onPressed: controller.sharing.value ? null : controller.sharePdf,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The report lists only what you logged. It does not interpret your results.',
            textAlign: TextAlign.center,
            style: AppText.tiny.copyWith(fontSize: 12, color: k.faint, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Reads the Rx value in its constructor, so the parent `Obx` tracks it.
class _Toggle extends StatelessWidget {
  _Toggle(this.label, this.rx) : on = rx.value;

  final String label;
  final RxBool rx;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return SwitchRow(
      label: label,
      value: on,
      onChanged: (v) => rx.value = v,
      padding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

class _PaperThumb extends StatelessWidget {
  const _PaperThumb();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget line(double w, [Color? c]) => Container(
          width: w,
          height: 4,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: c ?? k.border, borderRadius: BorderRadius.circular(2)),
        );
    return ExcludeSemantics(
      child: Container(
        width: 104,
        height: 146,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E2F3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('kindose report', style: AppText.tiny.copyWith(fontSize: 9, color: AppColors.ink, fontWeight: FontWeight.w800)),
            line(60, const Color(0xFFCFCBEA)),
            const SizedBox(height: 6),
            CustomPaint(size: const Size(84, 28), painter: _MiniLine()),
            line(80),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: 9,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: AppColors.tangerine, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ],
              ],
            ),
            line(70),
            line(50),
          ],
        ),
      ),
    );
  }
}

class _MiniLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, 5)
      ..lineTo(size.width * 0.27, 9)
      ..lineTo(size.width * 0.52, 15)
      ..lineTo(size.width * 0.76, 21)
      ..lineTo(size.width - 2, 25);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MiniLine oldDelegate) => false;
}
