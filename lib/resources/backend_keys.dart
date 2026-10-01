/// Public keys for the Kindose backend. These are meant to ship inside the
/// app: the publishable key only allows what the database rules allow.
///
/// Never put a secret key, service-role key or database password here.
class BackendKeys {
  BackendKeys._();

  static const String supabaseUrl = 'https://znwxockfqnacqjkgupfw.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_X_87Nv5ADhtdkukpKDAR7Q_d35stGmI';

  /// Google OAuth client IDs (Google Cloud Console → Credentials).
  /// Web client = the one pasted into Supabase → Auth → Google.
  /// Empty until created; the Google button then explains it isn't ready.
  static const String googleWebClientId =
      '742604804840-9m7t6l343ebjbhlvntvj478oj7j17tet.apps.googleusercontent.com';
  static const String googleIosClientId =
      '742604804840-uacmtnmgr2firv2bb5d5ahv3ed35e394.apps.googleusercontent.com';

  // RevenueCat public SDK keys (safe in the app, like the publishable key).
  // The Test Store key is used in debug builds only; release builds use
  // the platform keys and must never ship with the test key.
  static const String revenueCatTestKey = 'test_LkxKkxiyeybNCSlgrHzEexEyfxZ';
  static const String revenueCatAppleKey = ''; // appl_… (after App Store setup)
  static const String revenueCatGoogleKey = ''; // goog_… (after Play setup)

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get hasGoogle => googleWebClientId.isNotEmpty;
}
