import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/theme/theme.dart';

/// Pops the top route (page, sheet or dialog) directly on the navigator.
void popRoute() => Get.key.currentState?.pop();

// ---------------------------------------------------------------- toasts
//
// Our own toast instead of GetX snackbars. GetX queues snackbars: ten fast
// "+ glass" taps meant ten toasts shown one after another, and while one is
// open `Get.back()` closes it instead of the screen. Here there is one
// toast at a time: a new message replaces the text in place and restarts
// the timer, nothing queues, and a toast without a button lets every tap
// through (it never blocks the screen under it).

const Duration _toastDuration = Duration(milliseconds: 2200);

/// Same height as the floating tab bar in home_screen.dart, so a toast
/// sits just above it.
const double _navHeight = 68;

class _Toast {
  const _Toast(this.message, this.duration, {this.action, this.onAction});

  final String message;
  final Duration duration;
  final String? action;
  final Future<void> Function()? onAction;
}

final ValueNotifier<_Toast?> _toast = ValueNotifier<_Toast?>(null);
OverlayEntry? _entry;

void _show(_Toast t) {
  final overlay = Get.key.currentState?.overlay;
  if (overlay == null) return;
  final entry = _entry;
  if (entry == null || !entry.mounted) {
    _entry = OverlayEntry(builder: (_) => const _ToastHost());
    overlay.insert(_entry!);
  }
  _toast.value = t;
  // Read out by screen readers. (Newer Flutter suggests sendAnnouncement;
  // this one still works on every version we support.)
  // ignore: deprecated_member_use
  SemanticsService.announce(t.message, TextDirection.ltr);
}

/// Hides the toast now, if one is showing.
void hideToast() => _toast.value = null;

/// Short confirmation at the bottom of the screen, above the tab bar.
/// Safe to call on every tap: the same message while it's still showing
/// is ignored, and a new one replaces it at once.
void showToast(String message, {Duration duration = _toastDuration}) {
  final current = _toast.value;
  if (current != null && current.action == null && current.message == message) {
    return;
  }
  _show(_Toast(message, duration));
}

/// Toast with an Undo button. [onUndo] runs at most once.
void showUndoToast(String message, Future<void> Function() onUndo) =>
    showActionToast(
      message,
      'Undo',
      onUndo,
      duration: const Duration(milliseconds: 3500),
    );

/// Toast with one button, e.g. "Settings". [onTap] runs at most once.
void showActionToast(
  String message,
  String action,
  Future<void> Function() onTap, {
  Duration duration = const Duration(milliseconds: 4000),
}) {
  _show(_Toast(message, duration, action: action, onAction: onTap));
}

class _ToastHost extends StatefulWidget {
  const _ToastHost();

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );
  Timer? _timer;

  /// What's on screen; kept while it animates out.
  _Toast? _shown;
  bool _actionUsed = false;

  @override
  void initState() {
    super.initState();
    _toast.addListener(_changed);
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.dismissed && _toast.value == null) {
        _entry?.remove();
        _entry = null;
      }
    });
    _changed();
  }

  @override
  void dispose() {
    _toast.removeListener(_changed);
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _changed() {
    final t = _toast.value;
    _timer?.cancel();
    if (t == null) {
      _anim.reverse();
      return;
    }
    setState(() {
      _shown = t;
      _actionUsed = false;
    });
    _anim.forward();
    _timer = Timer(t.duration, () {
      if (identical(_toast.value, t)) _toast.value = null;
    });
  }

  Future<void> _tapAction() async {
    final t = _shown;
    if (t == null || _actionUsed) return;
    _actionUsed = true;
    hideToast();
    await t.onAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = _shown;
    if (t == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final bottom = keyboard > 0
        ? keyboard + 16
        : math.max(mq.viewPadding.bottom, 12) + _navHeight + 12;
    final curve = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final box = Container(
      padding: EdgeInsets.fromLTRB(18, 14, t.action == null ? 18 : 6, 14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.message,
              style: AppText.bodyStrong.copyWith(color: AppColors.white),
            ),
          ),
          if (t.action != null)
            TextButton(
              onPressed: _tapAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lime,
                minimumSize: const Size(64, 44),
              ),
              child: Text(
                t.action!,
                style: AppText.title.copyWith(color: AppColors.lime),
              ),
            ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          bottom: bottom,
          child: FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.35),
                end: Offset.zero,
              ).animate(curve),
              // A plain toast lets taps through to the screen under it.
              child: IgnorePointer(
                ignoring: t.action == null,
                child: Material(type: MaterialType.transparency, child: box),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
