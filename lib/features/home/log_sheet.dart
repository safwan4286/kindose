import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../resources/routes.dart';
import '../../services/theme/theme.dart';
import '../../services/tracker_service.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/toast.dart';
import 'weight_sheet.dart';

/// "What are you logging?" sheet opened from the + button.
Future<void> showLogSheet() {
  return Get.bottomSheet<void>(const LogSheet(), isScrollControlled: true);
}

class LogSheet extends StatelessWidget {
  const LogSheet({super.key});

  void _goTo(String route, [Object? args]) {
    popRoute();
    Get.toNamed<void>(route, arguments: args);
  }

  Future<void> _quickProtein(int g, String label) async {
    popRoute();
    await Get.find<TrackerService>().addProtein(g);
    showToast('Added $label');
  }

  Future<void> _quickWater() async {
    popRoute();
    await Get.find<TrackerService>().addWater(250);
    showToast('Added a glass of water');
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: k.border, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('What are you logging?', style: AppText.h2.copyWith(fontSize: 26))),
                CircleIconButton(icon: PhosphorIconsBold.x, label: 'Close', size: 40, onTap: () => popRoute()),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.98,
              children: [
                _Tile('Dose', Img3d.syringe, AppColors.hero, AppColors.white, () => _goTo(Routes.logDose)),
                _Tile('Protein', Img3d.egg, AppColors.tangerineSoft, AppColors.ink, () => _goTo(Routes.addIntake, 'protein')),
                _Tile('Water', Img3d.droplet, AppColors.aquaSoft, AppColors.ink, () => _goTo(Routes.addIntake, 'water')),
                _Tile('Weight', Img3d.chartDown, k.card, k.text, () {
                  popRoute();
                  showWeightSheet();
                }),
                _Tile('How I feel', Img3d.nauseated, AppColors.limeSoft, AppColors.ink, () => _goTo(Routes.checkIn)),
                _Tile('Note', Img3d.clipboard, AppColors.violetSoft, AppColors.ink, () => _goTo(Routes.checkIn, 'note')),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('One-tap favourites'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Favourite(Img3d.whey, 'Whey · 24 g', () => _quickProtein(24, '24 g protein')),
                _Favourite(Img3d.egg, '2 eggs · 12 g', () => _quickProtein(12, '12 g protein')),
                _Favourite(Img3d.droplet, 'Glass of water', _quickWater),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.icon, this.bg, this.fg, this.onTap);

  final String label;
  final String icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log $label',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThreeD(icon, size: 46),
                const Spacer(),
                Text(
                  label,
                  style: AppText.title.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Favourite extends StatelessWidget {
  const _Favourite(this.icon, this.label, this.onTap);

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.k.card,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThreeD(icon, size: 26),
              const SizedBox(width: 6),
              Text(label, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
