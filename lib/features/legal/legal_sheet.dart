import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/app_links.dart';
import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/toast.dart';
import '../../widgets/safe_bottom.dart';

/// Terms, privacy, medical disclaimer and credits in one sheet.
/// The wording here is a plain-English draft. Have a lawyer review it
/// before the store release.
Future<void> showLegalSheet() {
  return Get.bottomSheet<void>(const LegalSheet(), isScrollControlled: true);
}

class LegalSheet extends StatelessWidget {
  const LegalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.sp),
            Container(
              width: 40.sp,
              height: 5.sp,
              decoration: BoxDecoration(
                color: k.border,
                borderRadius: BorderRadius.circular(3.sp),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 12.sp),
                children: [
                  Text(
                    'Terms & privacy',
                    style: AppText.h2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 10.sp),
                  Row(
                    children: [
                      Expanded(
                        child: SoftButton(
                          label: 'Privacy Policy',
                          height: 44,
                          onPressed: () => AppLinks.open(AppLinks.privacyUrl),
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: SoftButton(
                          label: 'Terms of Use',
                          height: 44,
                          onPressed: () => AppLinks.open(AppLinks.termsUrl),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.sp),
                  const _Block(
                    title: 'Not medical advice',
                    body:
                        'Kindose is a personal log. It is not a medical device and does not diagnose, treat or suggest doses. '
                        'Always follow your doctor or pharmacist. If you feel very unwell, get medical help right away.',
                  ),
                  const _Block(
                    title: 'Adults only',
                    body: 'Kindose is for people aged 18 or older.',
                  ),
                  const _Block(
                    title: 'Your data stays on this phone',
                    body:
                        'There is no account and no server. What you log is stored only on this device. '
                        'You can export it or delete all of it at any time from Me.',
                  ),
                  const _Block(
                    title: 'Medicine names',
                    body:
                        'Medicine names are trademarks of their owners and are shown only so you can record what you take. '
                        'Kindose is not linked to any drug maker.',
                  ),
                  const _Block(
                    title: 'Credits',
                    body:
                        '3D illustrations: Microsoft Fluent Emoji (MIT). Icons: Phosphor Icons (MIT). '
                        'Fonts: Figtree and Bricolage Grotesque (SIL Open Font License).',
                  ),
                  SizedBox(height: 6.sp),
                  SoftButton(
                    label: 'View all licences',
                    background: k.card,
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: 'Kindose',
                      applicationLegalese:
                          'A personal GLP-1 log. Not medical advice.',
                    ),
                  ),
                  SizedBox(height: 10.sp),
                  SoftButton(
                    label: 'Close',
                    background: AppColors.ink,
                    foreground: AppColors.white,
                    onPressed: () => popRoute(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.sp),
      child: KCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title.copyWith(fontSize: 15.sp)),
            SizedBox(height: 4.sp),
            Text(
              body,
              style: AppText.bodyText.copyWith(
                fontSize: 14.sp,
                color: context.k.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
