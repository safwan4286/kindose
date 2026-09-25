import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';

class CommonScrollBar extends StatelessWidget {
  const CommonScrollBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      thumbColor: AppColors.common5D6A85,
      trackColor: AppColors.greyDCE1E8,
      thickness: 5.sp,
      minThumbLength: 20,
      trackVisibility: true,
      thumbVisibility: true,
      child: child,
    );
  }
}
