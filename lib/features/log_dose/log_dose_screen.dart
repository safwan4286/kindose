import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/catalog.dart';
import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/painters.dart';
import 'log_dose_controller.dart';
import '../../widgets/toast.dart';

class LogDoseScreen extends GetView<LogDoseController> {
  const LogDoseScreen({super.key});

  String _painFace(int p) {
    if (p <= 2) return Img3d.great;
    if (p <= 4) return Img3d.smile;
    if (p <= 6) return Img3d.neutral;
    if (p <= 8) return Img3d.frown;
    return Img3d.weary;
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Row(
                children: [
                  BackCircle(onTap: () => popRoute()),
                  Expanded(
                    child: Center(
                      child: Semantics(header: true, child: Text('Log dose', style: AppText.h2)),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: [
                  Obx(() {
                    final med = controller.medicine;
                    return KCard(
                      radius: 24,
                      child: Row(
                        children: [
                          if (med == null || med.isTablet)
                            const ThreeD(Img3d.pill, size: 44)
                          else
                            PenArt(body: med.color, cap: med.dark, height: 62),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(controller.medicineTitle, style: AppText.h3),
                                const SizedBox(height: 2),
                                Text(
                                  '${Dates.relativeDay(controller.takenAt.value, DateTime.now())}, '
                                  '${Dates.time(controller.takenAt.value)} · ${controller.formLabel}',
                                  style: AppText.small.copyWith(color: k.muted),
                                ),
                              ],
                            ),
                          ),
                          SoftButton(
                            label: 'Edit',
                            height: 36,
                            background: k.cardAlt,
                            foreground: AppColors.violet,
                            onPressed: () => controller.pickDateTime(context),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (!controller.isTablet) ...[
                    const SizedBox(height: 12),
                    const _SitePicker(),
                    const SizedBox(height: 12),
                    Obx(() {
                      final p = controller.pain.value;
                      return KCard(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ThreeD(_painFace(p), size: 38),
                                const SizedBox(width: 10),
                                Expanded(child: Text('How much did it hurt?', style: AppText.title)),
                                Text.rich(TextSpan(children: [
                                  TextSpan(text: '$p', style: AppText.number(24).copyWith(color: k.text)),
                                  TextSpan(text: '/10', style: AppText.small.copyWith(color: k.muted)),
                                ])),
                              ],
                            ),
                            Slider(
                              value: p.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              semanticFormatterCallback: (v) => 'Pain ${v.round()} out of 10',
                              onChanged: (v) => controller.pain.value = v.round(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),
                  Obx(() => controller.showNote.value
                      ? TextField(
                          controller: controller.noteCtrl,
                          maxLines: 3,
                          maxLength: 280,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(hintText: 'Anything worth remembering?'),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => controller.showNote.value = true,
                            icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 18, color: AppColors.violet),
                            label: Text('Add a note', style: AppText.title.copyWith(color: AppColors.violet)),
                          ),
                        )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Obx(() => PillButton(
                    label: 'Save dose',
                    icon: PhosphorIconsBold.check,
                    busy: controller.saving.value,
                    onPressed: controller.save,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SitePicker extends GetView<LogDoseController> {
  const _SitePicker();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Obx(() {
      final chosen = controller.site.value;
      final last = controller.lastSite;
      final suggested = controller.suggestedSite;
      return KCard(
        radius: 26,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              height: 250,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _BodyPainter(k.tint, k.faint))),
                  for (final s in Catalog.sites)
                    Positioned(
                      left: s.x,
                      top: s.y,
                      child: Semantics(
                        button: true,
                        selected: s.id == chosen,
                        label: '${s.name}${s.id == last ? ', last used' : ''}${s.id == suggested ? ', suggested' : ''}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => controller.site.value = s.id,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: s.id == chosen ? AppColors.violet : k.card,
                              shape: BoxShape.circle,
                              border: s.id == chosen
                                  ? null
                                  : Border.all(
                                      color: s.id == last ? AppColors.tangerine : k.border,
                                      width: s.id == last ? 4 : 2,
                                    ),
                              boxShadow: s.id == chosen
                                  ? [BoxShadow(color: AppColors.violet.withValues(alpha: 0.25), spreadRadius: 6)]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Injection site'),
                    const SizedBox(height: 8),
                    Text(Catalog.siteName(chosen), style: AppText.h2),
                    if (chosen == suggested) ...[
                      const SizedBox(height: 8),
                      const KTag('Suggested next', bg: AppColors.limeSoft, fg: AppColors.limeText),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Rotating sites gives your skin time to recover.',
                      style: AppText.small.copyWith(color: k.muted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _Legend(color: AppColors.violet, label: 'Chosen', filled: true),
                    _Legend(color: AppColors.tangerine, label: 'Last used'),
                    _Legend(color: k.border, label: 'Available'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.filled = false});

  final Color color;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: filled ? color : context.k.card,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: color, width: 3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppText.tiny.copyWith(fontSize: 12, color: context.k.muted)),
        ],
      ),
    );
  }
}

/// Simple front-facing body outline for the 160 × 250 site map.
class _BodyPainter extends CustomPainter {
  _BodyPainter(this.fill, this.label);

  final Color fill;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = fill;
    canvas.drawCircle(const Offset(80, 28), 20, p);
    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));
    canvas.drawRRect(r(46, 54, 68, 100, 24), p);
    canvas.drawRRect(r(20, 58, 22, 96, 11), p);
    canvas.drawRRect(r(118, 58, 22, 96, 11), p);
    canvas.drawRRect(r(50, 148, 28, 100, 13), p);
    canvas.drawRRect(r(82, 148, 28, 100, 13), p);
    for (final e in [('R', 6.0), ('L', 146.0)]) {
      final tp = TextPainter(
        text: TextSpan(text: e.$1, style: AppText.tiny.copyWith(color: label, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(e.$2, 228));
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.fill != fill || old.label != label;
}
