import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/backend/backend_service.dart';
import '../services/purchases/purchase_service.dart';
import '../resources/colors.dart';
import 'buttons.dart';
import 'k_sheet.dart';

/// Start-up internet check. App updates, Plus prices and offers come from
/// the server, so an offline start says so. Logging keeps working; the
/// refresh happens by itself when the connection is back
/// ([BackendService] listens for it).
class OfflineNotice {
  OfflineNotice._();

  static bool _shown = false;

  static Future<bool> isOnline() async {
    final r = await Connectivity().checkConnectivity();
    return r.any((c) => c != ConnectivityResult.none);
  }

  /// Once per launch, after the first screen is up.
  static Future<void> atLaunch() async {
    if (_shown) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (await isOnline()) return;
    _shown = true;
    await Get.bottomSheet<void>(
      const _OfflineSheet(),
      isScrollControlled: true,
    );
  }

  /// Fresh config and Plus prices (also called when the connection returns).
  static Future<void> refresh() async {
    if (Get.isRegistered<BackendService>()) {
      await Get.find<BackendService>().loadConfig();
    }
    if (Get.isRegistered<PurchaseService>()) {
      await Get.find<PurchaseService>().loadOfferings();
    }
  }
}

class _OfflineSheet extends StatefulWidget {
  const _OfflineSheet();

  @override
  State<_OfflineSheet> createState() => _OfflineSheetState();
}

class _OfflineSheetState extends State<_OfflineSheet> {
  bool _checking = false;
  bool _stillOffline = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final online = await OfflineNotice.isOnline();
    if (online) await OfflineNotice.refresh();
    if (!mounted) return;
    if (online) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _checking = false;
        _stillOffline = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      icon: KIconTile(icon: Icons.wifi_off_rounded, bg: k.cardAlt, fg: k.text),
      title: "You're offline",
      sub: _stillOffline
          ? 'Still no connection. Check your Wi-Fi or mobile data. You can keep logging in the meantime.'
          : 'Kindose needs the internet for app updates, Plus and backup. '
                'You can keep logging, and everything refreshes by itself when you are back online.',
      children: [
        SoftButton(
          label: _checking ? 'Checking…' : 'Try again',
          height: 50,
          background: k.text,
          foreground: k.bg,
          onPressed: _checking ? null : _retry,
        ),
        const SizedBox(height: 8),
        LinkButton(
          label: 'Continue offline',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
