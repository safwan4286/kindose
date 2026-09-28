import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../me/me_screen.dart';
import '../progress/progress_screen.dart';
import '../report/report_screen.dart';
import '../today/today_screen.dart';
import 'home_controller.dart';

/// Tab shell with the floating pill navigation from the design.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => IndexedStack(
              index: controller.tab.value.index,
              children: const [
                TodayScreen(),
                ProgressScreen(),
                ReportScreen(),
                MeScreen(),
              ],
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: _FloatingNav(),
          ),
        ],
      ),
    );
  }
}

/// Bottom padding every tab adds so content can scroll above the nav.
const double kNavClearance = 110;

class _FloatingNav extends GetView<HomeController> {
  const _FloatingNav();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: k.nav,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: k.bg == KColors.dark.bg ? 0.5 : 0.14,
              ),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Obx(() {
          final t = controller.tab.value;
          return Row(
            children: [
              _NavItem(
                icon: PhosphorIconsDuotone.house,
                label: 'Today',
                active: t == HomeTab.today,
                onTap: () => controller.select(HomeTab.today),
              ),
              _NavItem(
                icon: PhosphorIconsDuotone.chartLineUp,
                label: 'Progress',
                active: t == HomeTab.progress,
                onTap: () => controller.select(HomeTab.progress),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Semantics(
                      button: true,
                      label: 'Log something',
                      child: Material(
                        color: k.fab,
                        shape: const CircleBorder(),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.4),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: controller.openLogSheet,
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: Center(
                              child: PhosphorIcon(
                                PhosphorIconsBold.plus,
                                size: 26,
                                color: k.fabIcon,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: PhosphorIconsDuotone.fileText,
                label: 'Doctor report',
                active: t == HomeTab.report,
                onTap: () => controller.select(HomeTab.report),
              ),
              _NavItem(
                icon: PhosphorIconsDuotone.userCircle,
                label: 'Me',
                active: t == HomeTab.me,
                onTap: () => controller.select(HomeTab.me),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final PhosphorDuotoneIconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: Tooltip(
            message: label,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active ? k.navActiveBg : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    icon,
                    size: 24,
                    color: active ? k.navActiveFg : k.faint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
