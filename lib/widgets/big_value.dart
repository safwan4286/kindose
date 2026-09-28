import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'press_scale.dart';

/// Huge number with its unit ("70.5 kg", "5′ 7″") and a "Tap the number to
/// type it" hint. Tapping calls [onTap], usually `askNumber`.
class BigValue extends StatelessWidget {
  const BigValue({
    super.key,
    required this.value,
    required this.onTap,
    required this.semanticLabel,
    this.unit,
    this.hint = 'Tap the number to type it',
    this.color,
  });

  final String value;
  final String? unit;
  final VoidCallback onTap;
  final String semanticLabel;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      children: [
        Semantics(
          button: true,
          label: '$semanticLabel. Tap to type it',
          excludeSemantics: true,
          child: PressScale(
            onTap: () {
              Haptics.instance.selectionClick();
              onTap();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: k.border, width: 2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: AppText.h1.copyWith(
                      fontSize: 72.sp,
                      height: 1,
                      letterSpacing: -2.5,
                      color: color ?? k.text,
                    ),
                  ),
                  if (unit != null) ...[
                    SizedBox(width: 6.sp),
                    Text(
                      unit!,
                      style: AppText.title.copyWith(
                        fontSize: 20.sp,
                        color: k.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          SizedBox(height: 10.sp),
          ExcludeSemantics(
            child: Text(
              hint!,
              style: AppText.small.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: k.faint,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
