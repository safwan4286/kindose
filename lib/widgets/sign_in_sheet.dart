import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'k_sheet.dart';
import 'social_button.dart';

/// Which account to sign in with. Android only has Google, so it skips the
/// sheet; iOS offers Apple first, as Apple's rules ask.
Future<SocialProvider?> chooseSignIn({
  String title = 'Sign in',
  String? sub,
}) async {
  if (!Platform.isIOS) return SocialProvider.google;
  return Get.bottomSheet<SocialProvider>(
    _SignInSheet(title: title, sub: sub),
    isScrollControlled: true,
  );
}

class _SignInSheet extends StatelessWidget {
  const _SignInSheet({required this.title, this.sub});

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return KSheetFrame(
      title: title,
      sub: sub,
      children: [
        SocialButton(
          provider: SocialProvider.apple,
          onPressed: () => Navigator.of(context).pop(SocialProvider.apple),
        ),
        SizedBox(height: 10.sp),
        SocialButton(
          provider: SocialProvider.google,
          onPressed: () => Navigator.of(context).pop(SocialProvider.google),
        ),
        SizedBox(height: 14.sp),
        Text(
          'Only your name and email are shared with Kindose.',
          textAlign: TextAlign.center,
          style: AppText.small.copyWith(
            fontSize: 12.sp,
            color: context.k.faint,
          ),
        ),
        SizedBox(height: 6.sp),
      ],
    );
  }
}
