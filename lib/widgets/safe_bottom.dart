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
