import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
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
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: k.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                children: [
                  Text('Terms & privacy', style: AppText.h2),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: KCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title),
            const SizedBox(height: 4),
            Text(
              body,
              style: AppText.bodyText.copyWith(color: context.k.muted),
            ),
          ],
        ),
      ),
    );
  }
}
