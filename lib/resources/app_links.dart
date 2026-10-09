import 'package:url_launcher/url_launcher.dart';

/// Public links shown in the app. Rows that use an empty value are hidden,
/// so nothing broken ships.
class AppLinks {
  AppLinks._();

  /// Support inbox for "Contact support" and privacy requests.
  static const String supportEmail = 'safwanbolwala.dev@gmail.com';

  /// Legal pages (repo folder `hosting/`, Firebase Hosting). Swap the base
  /// for a custom domain later; the paths stay the same.
  static const String webBase = 'https://kindose-96ea8.web.app';
  static const String privacyUrl = '$webBase/privacy';
  static const String termsUrl = '$webBase/terms';
  static const String deleteAccountUrl = '$webBase/delete-account';

  /// Store pages for "Rate Kindose".
  /// TODO(safwan): fill in once the store listings exist.
  static const String playStoreUrl = '';
  static const String appStoreUrl = '';

  /// Numeric App Store id (from App Store Connect, e.g. '6741234567'), for
  /// "Rate Kindose" on iOS. Empty until the listing exists.
  static const String appStoreId = '';

  /// Opens a web page in the in-app browser (falls back to the browser).
  static Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
    } catch (_) {}
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
