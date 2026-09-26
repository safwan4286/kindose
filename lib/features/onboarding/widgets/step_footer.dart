import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';

/// Bottom area of a single-choice question. Shows "Tap one to continue"
/// and, when an answer needs more input ("Custom dose", "Something else"),
/// smoothly grows into [panel] instead.
class StepFooter extends StatelessWidget {
  const StepFooter({
    super.key,
    this.expanded = false,
    this.panel,
    this.hint = 'Tap one to continue',
  });

  final bool expanded;
  final Widget? panel;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: expanded && panel != null ? panel! : TapHint(hint),
    );
  }
}

/// Small grey helper line under a question.
class TapHint extends StatelessWidget {
  const TapHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ExcludeSemantics(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.small.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.k.faint),
        ),
      ),
    );
  }
}

/// Extra input for an answer: optional label, the input itself, then the
/// shared Continue button (disabled while [onContinue] is null).
class StepInputPanel extends StatelessWidget {
  const StepInputPanel({
    super.key,
    this.label,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  final String? label;
  final Widget child;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(left: 4.sp, bottom: 8.sp),
            child: Text(
              label!,
              style: AppText.small.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: context.k.textSoft),
            ),
          ),
        child,
        SizedBox(height: 12.sp),
        PillButton(label: continueLabel, onPressed: onContinue),
      ],
    );
  }
}

/// Lock + reassurance line shown at the bottom of personal questions.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
      decoration: BoxDecoration(color: k.cardAlt, borderRadius: BorderRadius.circular(18.sp)),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsBold.lockSimple, size: 16.sp, color: k.textSoft),
          SizedBox(width: 10.sp),
          Expanded(
            child: Text(text, style: AppText.bodyText.copyWith(fontSize: 13.5.sp, color: k.textSoft)),
          ),
        ],
      ),
    );
  }
}
