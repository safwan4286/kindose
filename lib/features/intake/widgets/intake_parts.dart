import 'package:flutter/material.dart';

import '../../../resources/colors.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';

/// Small caps heading style used on the Protein and Water screens.
TextStyle intakeCaps(BuildContext c) => AppText.caps.copyWith(
  fontSize: 12.sp,
  letterSpacing: 1.1,
  color: c.k.muted,
);

/// "YOUR USUAL" style heading with an optional hint on the right.
class IntakeLabel extends StatelessWidget {
  const IntakeLabel(this.text, {super.key, this.trailing, this.top = 22});

  final String text;
  final String? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top.sp, bottom: 10.sp),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text.toUpperCase(), style: intakeCaps(context)),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                color: context.k.faint,
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded card with thin dividers between [children].
class IntakeCard extends StatelessWidget {
  const IntakeCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(22.sp),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: k.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
