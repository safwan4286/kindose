import 'dart:io';

import 'package:flutter/widgets.dart';

import '../services/responsiveness/device_manager.dart';

class KSafeArea extends StatelessWidget {
  final Widget child;
  final double iosBottomPadding;
  final bool topSafeArea;

  const KSafeArea({
    super.key,
    required this.child,
    this.iosBottomPadding = 0,
    this.topSafeArea = true,
  }) : assert(iosBottomPadding >= 0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: topSafeArea,
      bottom: !Platform.isIOS,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: Platform.isIOS ? iosBottomPadding.sp : 0,
        ),
        child: child,
      ),
    );
  }
}

/// Root of a bottom sheet. iOS: same as [KSafeArea]. Android: the sheet's
/// [color] runs on under the navigation bar to the bottom edge (the app is
/// edge to edge), instead of the sheet stopping above the bar with the dim
/// background showing below it. The content still stays above the bar.
class KSheetSafeArea extends StatelessWidget {
  const KSheetSafeArea({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) return KSafeArea(child: child);
    final bar = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Builder(
        builder: (inner) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: MediaQuery.removePadding(
                context: inner,
                removeBottom: true,
                child: child,
              ),
            ),
            if (bar > 0) ColoredBox(color: color, child: SizedBox(height: bar)),
          ],
        ),
      ),
    );
  }
}

class KBottomPadding extends StatelessWidget {
  final Widget child;
  final double iosPadding;

  const KBottomPadding({super.key, required this.child, this.iosPadding = 10})
    : assert(iosPadding >= 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Platform.isIOS ? iosPadding.sp : 0),
      child: child,
    );
  }
}
