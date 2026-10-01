import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/theme/theme.dart';
import 'buttons.dart';
import 'k_sheet.dart';

/// Only for actions that really need the internet (sign in, restore,
/// delete account, buying Plus). Logging never shows this: it saves on
/// the phone and backs up when the connection is back.
Future<void> showNoInternetSheet({String what = 'This'}) {
  Haptics.instance.lightImpact();
  return Get.bottomSheet<void>(
    _NoInternetSheet(what: what),
    isScrollControlled: true,
  );
}

class _NoInternetSheet extends StatelessWidget {
  const _NoInternetSheet({required this.what});

  final String what;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      icon: KIconTile(
        icon: Icons.wifi_off_rounded,
        bg: k.cardAlt,
        fg: k.text,
      ),
      title: "You're offline",
      sub: '$what needs the internet. Check your Wi-Fi or mobile data and try again. '
          'Anything you log still saves on this phone.',
      children: [
        SoftButton(
          label: 'OK',
          height: 50,
          background: k.text,
          foreground: k.bg,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
