import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/app_links.dart';
import '../../resources/colors.dart';
import '../../services/haptics/haptics.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';

/// Me → Medical sources: where Kindose's health information comes from.
/// Every link was opened and checked when added (Oct 2026). Re-check them
/// when goals, tips or the medicine list change.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const String _dm =
      'https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=';

  static const List<_Group> _groups = [
    _Group(PhosphorIconsRegular.syringe, 'Your medicines', [
      _Source(
        'Mounjaro (tirzepatide) prescribing information',
        'FDA label · DailyMed',
        '${_dm}d2d7da5d-ad07-4228-955f-cf7e355c8cc0',
      ),
      _Source(
        'Zepbound (tirzepatide) prescribing information',
        'FDA label · DailyMed',
        '${_dm}487cd7e7-434c-4925-99fa-aa80b1cc776b',
      ),
      _Source(
        'Ozempic (semaglutide) prescribing information',
        'FDA label · DailyMed',
        '${_dm}adec4fd2-6858-4c99-91d4-531f5f2a2d79',
      ),
      _Source(
        'Ozempic pill and Rybelsus (oral semaglutide)',
        'FDA label · DailyMed',
        '${_dm}27f15fac-7d98-4114-a2ec-92494a91da98',
      ),
      _Source(
        'Wegovy (semaglutide) injection and tablets',
        'FDA label · DailyMed',
        '${_dm}ee06186f-2aa3-4990-a760-757579d8f77b',
      ),
      _Source(
        'Foundayo (orforglipron) prescribing information',
        'FDA label · DailyMed',
        '${_dm}8ac446c5-feba-474f-a103-23facb9b5c62',
      ),
      _Source(
        'Saxenda (liraglutide) prescribing information',
        'FDA label · DailyMed',
        '${_dm}3946d389-0926-4f77-a708-0acb8153b143',
      ),
      _Source(
        'Trulicity (dulaglutide) prescribing information',
        'FDA label · DailyMed',
        '${_dm}463050bd-2b1c-40f5-b3c3-0a04bb433309',
      ),
    ]),
    _Group(PhosphorIconsRegular.forkKnife, 'Protein, food and muscle', [
      _Source(
        'Nutritional priorities to support GLP-1 therapy for obesity (2025)',
        'Joint advisory · ACLM, ASN, OMA, The Obesity Society',
        'https://pmc.ncbi.nlm.nih.gov/articles/PMC12304835/',
      ),
      _Source(
        'Position stand: protein and exercise (2017)',
        'International Society of Sports Nutrition',
        'https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/',
      ),
    ]),
    _Group(PhosphorIconsRegular.drop, 'Water', [
      _Source(
        'Dietary Reference Intakes for water (2005)',
        'National Academies of Sciences',
        'https://www.nationalacademies.org/publications/10925',
      ),
      _Source(
        'Water, drinks and hydration',
        'NHS',
        'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/',
      ),
    ]),
    _Group(PhosphorIconsRegular.personSimple, 'Body mass index (BMI)', [
      _Source(
        'Obesity and overweight: BMI classification',
        'World Health Organization',
        'https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: k.bg,
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 4.sp),
              child: Row(children: [BackCircle(onTap: popRoute)]),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.sp, 6.sp, 20.sp, 32.sp),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Medical sources',
                      style: AppText.h1.copyWith(
                        fontSize: 28.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.sp),
                  Text(
                    'Kindose’s goals, tips and medicine list are based on these '
                    'official sources. Tap one to open it. Your doctor or '
                    'pharmacist knows your situation best.',
                    style: AppText.bodyText.copyWith(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: k.muted,
                    ),
                  ),
                  for (final (i, g) in _groups.indexed) ...[
                    _GroupLabel(icon: g.icon, title: g.title),
                    KGroup(
                      children: [for (final s in g.sources) _SourceRow(s)],
                    ).enter(motion, delay: 140 + i * 60, dy: 0.04),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group {
  const _Group(this.icon, this.title, this.sources);

  final IconData icon;
  final String title;
  final List<_Source> sources;
}

class _Source {
  const _Source(this.title, this.publisher, this.url);

  final String title;
  final String publisher;
  final String url;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.only(top: 22.sp, bottom: 10.sp, left: 4.sp),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            PhosphorIcon(icon, size: 18.sp, color: k.muted),
            SizedBox(width: 8.sp),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppText.caps.copyWith(
                  fontSize: 12.sp,
                  letterSpacing: 1.1,
                  color: k.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow(this.source);

  final _Source source;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PressScale(
      semanticLabel: '${source.title}, ${source.publisher}. Opens in browser',
      onTap: () {
        Haptics.instance.selectionClick();
        AppLinks.open(source.url);
      },
      child: Container(
        color: Colors.transparent,
        constraints: BoxConstraints(minHeight: 56.sp),
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: AppText.title.copyWith(
                      fontSize: 14.5.sp,
                      height: 1.3,
                      color: k.text,
                    ),
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    source.publisher,
                    style: AppText.small.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: k.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.sp),
            PhosphorIcon(
              PhosphorIconsRegular.arrowSquareOut,
              size: 18.sp,
              color: k.faint,
            ),
          ],
        ),
      ),
    );
  }
}
