import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../resources/images.dart';
import '../../services/plus/plus_access.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../widgets/press_scale.dart';
import '../me/me_screen.dart';
import '../progress/progress_screen.dart';
import '../report/report_screen.dart';
import '../today/today_screen.dart';
import '../today/widgets/free_week.dart';
import 'home_controller.dart';

/// Tab shell with the floating pill navigation from the design.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read here, above the Scaffold: inside the body the Scaffold removes
    // the keyboard inset (it resizes the body instead), so it reads 0.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => _TabFade(
              index: controller.tab.value.index,
              child: IndexedStack(
                index: controller.tab.value.index,
                children: [
                  const TodayScreen(),
                  // After the free week these two tabs ask for Plus.
                  PlusAccess.unlocked
                      ? const ProgressScreen()
                      : const LockedTab(
                          title: 'Your progress is waiting',
                          sub:
                              'Charts, trends and how you felt since day one, with Plus.',
                          icon: Img3d.chartUp,
                        ),
                  PlusAccess.unlocked
                      ? const ReportScreen()
                      : const LockedTab(
                          title: 'Your doctor report',
                          sub:
                              'Doses, weight and side effects as a PDF for your next visit, with Plus.',
                          icon: Img3d.clipboard,
                        ),
                  const MeScreen(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 15.sp,
            right: 15.sp,
            bottom: 0,
            child: _HideWithKeyboard(
              open: keyboardOpen,
              child: _FloatingNav(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

const double _navHeight = 68;

/// Slides the nav down out of the way while the keyboard is open, so it
/// never covers the field being typed in (the screen above already moves
/// up for the keyboard).
class _HideWithKeyboard extends StatelessWidget {
  const _HideWithKeyboard({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: motion ? 200 : 0);
    return IgnorePointer(
      ignoring: open,
      child: ExcludeSemantics(
        excluding: open,
        child: AnimatedSlide(
          offset: open ? const Offset(0, 1.6) : Offset.zero,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: open ? 0 : 1,
            duration: duration,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Bottom padding every tab adds so its content can scroll above the nav.
double get kNavClearance =>
    _navHeight + math.max(12.0, DeviceManager.instance.bottomBarHeight) + 40;

/// Quick fade + lift when the tab changes. Keeps the [IndexedStack]
/// (and each tab's scroll position) alive.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SafeArea(
      // Keeps a gap on phones without a gesture bar.
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: _navHeight,
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
          Widget item(HomeTab tab, IconData icon, String label) => _NavItem(
            icon: icon,
            label: label,
            active: t == tab,
            onTap: () => controller.tapTab(tab),
          );
          return Row(
            children: [
              item(HomeTab.today, PhosphorIconsBold.house, 'Today'),
              item(HomeTab.progress, PhosphorIconsBold.chartLineUp, 'Progress'),
              Expanded(
                child: Center(
                  child: _LogButton(
                    open: controller.logOpen.value,
                    onTap: controller.openLogSheet,
                  ),
                ),
              ),
              item(HomeTab.report, PhosphorIconsBold.fileText, 'Doctor report'),
              item(HomeTab.me, PhosphorIconsBold.userCircle, 'Me'),
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

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: Tooltip(
            message: label,
            child: PressScale(
              pressedScale: 0.88,
              onTap: onTap,
              child: AnimatedContainer(
                duration: Duration(milliseconds: motion ? 220 : 0),
                curve: Curves.easeOutCubic,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active
                      ? k.navActiveBg
                      : k.navActiveBg.withValues(alpha: 0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: active ? k.navActiveFg : k.faint),
                    duration: Duration(milliseconds: motion ? 200 : 0),
                    builder: (_, c, _) => TweenAnimationBuilder<double>(
                      // Re-keyed on change so the newly picked icon pops in.
                      key: ValueKey(active),
                      tween: Tween<double>(
                        begin: active && motion ? 0.75 : 1.0,
                        end: 1.0,
                      ),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Icon(icon, size: 24, color: c),
                    ),
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

/// Raised lime + button. Turns into an x while the log sheet is open.
class _LogButton extends StatelessWidget {
  const _LogButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Semantics(
        button: true,
        label: open ? 'Close log' : 'Log something',
        excludeSemantics: true,
        child: PressScale(
          pressedScale: 0.9,
          onTap: onTap,
          child: Material(
            color: k.fab,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Center(
                child: AnimatedRotation(
                  turns: open ? 0.125 : 0,
                  duration: Duration(milliseconds: motion ? 260 : 0),
                  curve: Curves.easeOutBack,
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
    );
  }
}
