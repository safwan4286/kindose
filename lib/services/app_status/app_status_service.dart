import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../resources/app_links.dart';
import '../../resources/routes.dart';
import '../app_info.dart';

/// A message shown at the top of Today, set from the backend.
class AppBanner {
  const AppBanner({
    required this.id,
    required this.text,
    this.level = 'info',
    this.url,
  });

  /// Change the id to show a new banner to people who closed the last one.
  final String id;
  final String text;

  /// 'info' (calm) or 'warning' (amber).
  final String level;

  /// Optional "Learn more" link.
  final String? url;

  static AppBanner? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final text = j['text'];
    if (id is! String || id.isEmpty || text is! String || text.trim().isEmpty) {
      return null;
    }
    final level = j['level'];
    final url = j['url'];
    return AppBanner(
      id: id,
      text: text.trim(),
      level: level == 'warning' ? 'warning' : 'info',
      url: url is String && url.startsWith('https://') ? url : null,
    );
  }
}

/// Force update + announcement banner, from Supabase `app_config` key
/// `app`:
///
/// ```json
/// {
///   "min_version": "1.0.0",
///   "update_title": "Time to update",
///   "update_message": "This version is no longer supported…",
///   "banner": { "id": "oct-maint", "text": "…", "level": "info", "url": null }
/// }
/// ```
///
/// The last config is kept on the phone, so an old version stays blocked
/// even when it starts offline. Every key is optional.
class AppStatusService extends GetxService {
  static const String _cacheKey = 'appStatusConfig';
  static const String _dismissedKey = 'bannerDismissed';

  Box<dynamic> get _settings => Hive.box<dynamic>('settings');

  /// This version is below `min_version`: only the update screen shows.
  final RxBool mustUpdate = false.obs;
  final RxString updateTitle = 'Time to update'.obs;
  final RxString updateMessage =
      'This version of Kindose is no longer supported. Update to keep your '
              'doses, reminders and sync working. Your data is safe.'
          .obs;

  final Rxn<AppBanner> banner = Rxn<AppBanner>();
  final RxString dismissedBanner = ''.obs;

  Worker? _worker;

  AppStatusService init() {
    final d = _settings.get(_dismissedKey);
    dismissedBanner.value = d is String ? d : '';
    _apply(_settings.get(_cacheKey));
    _worker = ever(mustUpdate, (bool v) {
      if (v && Get.currentRoute != Routes.update) {
        Get.offAllNamed<void>(Routes.update);
      }
    });
    return this;
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// Backend JSON for the `app` key. Bad data is ignored.
  void applyRemote(Object? raw) {
    if (raw is! Map) return;
    _apply(raw);
    try {
      _settings.put(_cacheKey, Map<String, dynamic>.from(raw));
    } catch (_) {}
  }

  void _apply(Object? raw) {
    if (raw is! Map) return;
    final min = raw['min_version'];
    final title = raw['update_title'];
    final message = raw['update_message'];
    if (title is String && title.trim().isNotEmpty)
      updateTitle.value = title.trim();
    if (message is String && message.trim().isNotEmpty) {
      updateMessage.value = message.trim();
    }
    banner.value = AppBanner.fromJson(raw['banner']);
    String current;
    try {
      current = AppInfo().version;
    } catch (_) {
      return;
    }
    mustUpdate.value = min is String && isOlder(current, min);
    if (kDebugMode) {
      debugPrint(
        '[AppStatus] version $current · min ${min ?? '-'} · update ${mustUpdate.value}',
      );
    }
  }

  /// "1.2.3" < "1.10.0" compares part by part. Unknown parts count as 0.
  static bool isOlder(String current, String min) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final a = parts(current);
    final b = parts(min);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  /// The banner to show now, or null (none, or closed by the user).
  AppBanner? get visibleBanner {
    final b = banner.value;
    if (b == null || b.id == dismissedBanner.value) return null;
    return b;
  }

  Future<void> dismissBanner() async {
    final b = banner.value;
    if (b == null) return;
    dismissedBanner.value = b.id;
    await _settings.put(_dismissedKey, b.id);
  }

  /// Store page for the update button, or null when not known yet.
  static String? get storeUrl {
    if (Platform.isIOS) {
      return AppLinks.appStoreUrl.isEmpty ? null : AppLinks.appStoreUrl;
    }
    if (Platform.isAndroid) {
      return AppLinks.playStoreUrl.isEmpty
          ? 'https://play.google.com/store/apps/details?id=com.kindose.app'
          : AppLinks.playStoreUrl;
    }
    return null;
  }
}
