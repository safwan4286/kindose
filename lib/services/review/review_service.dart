import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../resources/app_links.dart';

/// "Enjoying Kindose?" — the store's own rating dialog.
///
/// Asked automatically at a few good moments (each at most once), never
/// twice within [minGap]. The phone also limits how often the dialog really
/// shows (Apple: 3 times a year), so a call may do nothing — that's fine.
/// Me → "Rate Kindose" always opens the store page instead.
class ReviewService {
  ReviewService._();

  /// When to ask.
  static const String onboarding = 'onboarding';
  static const String firstDose = 'firstDose';

  static const Duration minGap = Duration(days: 3);

  static const String _askedKey = 'reviewAsked';
  static const String _lastKey = 'reviewLastAt';

  static Box<dynamic> get _s => Hive.box<dynamic>('settings');

  static Set<String> get _asked {
    final raw = _s.get(_askedKey);
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  }

  /// Shows the rating dialog for [moment] if it wasn't asked before and the
  /// last ask is at least [minGap] ago. A moment skipped because of the gap
  /// stays open, so it can be asked the next time it comes up.
  static Future<void> maybeAsk(
    String moment, {
    Duration delay = const Duration(milliseconds: 1200),
  }) async {
    try {
      if (_asked.contains(moment)) return;
      final last = _s.get(_lastKey);
      if (last is int &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(last),
              ) <
              minGap) {
        return;
      }
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      // Let the screen settle first, so the dialog doesn't cover a moment
      // that is still animating in.
      await Future<void>.delayed(delay);
      await review.requestReview();
      await _s.put(_askedKey, [..._asked, moment]);
      await _s.put(_lastKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) debugPrint('[Review] $moment skipped: $e');
    }
  }

  /// Me → "Rate Kindose": the store page (works any time). Before the iOS
  /// App Store id exists, falls back to the in-app dialog.
  static Future<bool> openStore() async {
    final review = InAppReview.instance;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          AppLinks.appStoreId.isEmpty) {
        if (!await review.isAvailable()) return false;
        await review.requestReview();
        return true;
      }
      await review.openStoreListing(
        appStoreId: AppLinks.appStoreId.isEmpty ? null : AppLinks.appStoreId,
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Review] store page failed: $e');
      return false;
    }
  }
}
