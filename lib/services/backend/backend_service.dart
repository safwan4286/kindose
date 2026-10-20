import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../resources/backend_keys.dart';
import '../../widgets/social_button.dart';
import '../app_info.dart';
import '../app_status/app_status_service.dart';
import '../debug/test_data.dart';
import '../plus/access_service.dart';
import '../offers/offer_service.dart';
import '../notifications/notif_prefs.dart';
import '../supply/supply_service.dart';
import '../tracker_service.dart';

/// Debug-only log line: `[Backend] …`. Never logs tokens or keys, and
/// emails are masked. Nothing is printed in release builds.
void _log(String message) {
  if (kDebugMode) debugPrint('[Backend] $message');
}

/// "sa***@gmail.com".
String _mask(String? email) {
  if (email == null || !email.contains('@')) return '-';
  final at = email.indexOf('@');
  final name = email.substring(0, at);
  final shown = name.length <= 2 ? name.substring(0, 1) : name.substring(0, 2);
  return '$shown***${email.substring(at)}';
}

/// Result of an action, so screens can show the right message.
enum BackendResult { ok, cancelled, offline, notReady, failed }

/// A backup found in the cloud.
class CloudBackup {
  const CloudBackup({required this.data, required this.updatedAt});

  final Map<String, dynamic> data;
  final DateTime updatedAt;

  int _count(String box) {
    final boxes = data['boxes'];
    final b = boxes is Map ? boxes[box] : null;
    return b is Map ? b.length : 0;
  }

  /// For "We found your data": how many doses and weigh-ins it holds.
  int get doses => _count('doses');
  int get weighIns => _count('weights');
}

/// Sign-in (Google, via Supabase Auth), cloud backup / restore, account
/// deletion and remote config. The app keeps working fully offline; this
/// only adds a copy in the cloud.
class BackendService extends GetxService {
  final TrackerService tracker = Get.find<TrackerService>();

  /// Signed-in user, or null.
  final Rxn<User> user = Rxn<User>();

  /// When the cloud copy was last saved (null = none / unknown).
  final Rxn<DateTime> lastBackupAt = Rxn<DateTime>();
  final RxBool busy = false.obs;

  StreamSubscription<AuthState>? _authSub;
  Future<void>? _googleInit;
  Worker? _changes;
  StreamSubscription<BoxEvent>? _settingsSub;
  Timer? _autoTimer;
  bool _autoRunning = false;

  /// Set while the user decides between this phone and a cloud backup, so
  /// an automatic backup can't overwrite the cloud copy first.
  bool autoPaused = false;

  // ---------------------------------------------------- data ownership
  //
  // The phone's data belongs to one account (or to nobody: a guest).
  // * Automatic backup only uploads when it belongs to the signed-in
  //   account, so one account's data can never land in another's backup.
  // * Sign out and delete account clear the phone.
  // * Signing in decides: restore the account's backup, or claim the
  //   phone's guest data.

  static const String _ownerKey = 'dataOwner';
  static const String _pendingKey = 'syncPending';
  static const String _ownerMigratedKey = 'ownerMigrated';

  Box<dynamic> get _settings => Hive.box<dynamic>('settings');

  /// Settings about this phone or the app itself, not the user's log.
  /// Changing them never starts a backup (they are still in it).
  static const Set<String> _phoneOnlyKeys = {
    _ownerKey,
    _pendingKey,
    _ownerMigratedKey,
    'installedAt',
    'clockSeen',
    'accessConfig',
    'freeStartOverride',
    'debugPlus',
    'appStatusConfig',
    'bannerDismissed',
    'offerShows',
    'offerLastShown',
    'paywallCloses',
    'reviewAsked',
    'reviewLastAt',
    'guideHoldSecs',
    'refillAt',
    TestData.onKey,
    'debugRealData',
  };

  /// Changes on this phone that aren't in the cloud yet (offline, or the
  /// quiet time hasn't passed).
  final RxBool pending = false.obs;

  /// An automatic backup is planned for the end of the quiet time, so
  /// [pending] is expected and nothing needs the user.
  final RxBool autoQueued = false.obs;

  /// The last sync attempt failed for lack of internet (false: the server
  /// or something else refused it, so waiting to go online won't help).
  final RxBool lastFailOffline = true.obs;

  /// Why changes can't be synced at all right now, or null. Retrying
  /// won't help until this is sorted.
  String? get syncBlocked {
    if (!signedIn || !hasLocalData) return null;
    if (TestData.isOn) return 'Test data is on this phone. Remove it to sync';
    if (!ownsLocal) return 'This phone’s data belongs to another account';
    return null;
  }

  StreamSubscription<List<ConnectivityResult>>? _netSub;

  /// Account id the phone's data belongs to, or null for a guest.
  String? get dataOwner {
    final v = _settings.get(_ownerKey);
    return v is String ? v : null;
  }

  bool get hasLocalData => tracker.profile.value != null;

  /// Signed in and the phone's data is this account's.
  bool get ownsLocal => user.value != null && dataOwner == user.value!.id;

  /// The phone's data now belongs to the signed-in account.
  Future<void> claimLocal() async {
    final id = user.value?.id;
    if (id == null) return;
    await _settings.put(_ownerKey, id);
    _log('Phone data now belongs to ${_mask(email)}');
  }

  Future<void> _setPending(bool v) async {
    pending.value = v;
    try {
      await _settings.put(_pendingKey, v);
    } catch (_) {}
  }

  /// Quiet time after the last change before an automatic backup.
  static const Duration _autoDelay = Duration(seconds: 20);

  static bool _initialised = false;

  /// Call once in main() before runApp. Safe when keys are missing.
  static Future<void> initSupabase() async {
    if (!BackendKeys.hasSupabase || _initialised) return;
    try {
      await Supabase.initialize(
        url: BackendKeys.supabaseUrl,
        publishableKey: BackendKeys.supabasePublishableKey,
      );
      _initialised = true;
      _log('Supabase ready (${BackendKeys.supabaseUrl})');
    } catch (e) {
      _log('Supabase init failed: $e');
    }
  }

  bool get ready => _initialised;
  bool get signedIn => user.value != null;
  String? get email => user.value?.email;

  /// 'google' or 'apple' (how the user signed in), or null.
  String? get provider {
    final p = user.value?.appMetadata['provider'];
    return p is String ? p : null;
  }

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    if (!ready) return;
    user.value = _db.auth.currentUser;
    pending.value = _settings.get(_pendingKey) == true;
    // Phones from before ownership existed: a signed-in user's data with
    // no owner yet is theirs — once, on the first start of this version.
    // After that, signed in without an owner means the "Restore / Keep
    // this phone" choice was never finished (app killed): sign out (the
    // phone's data stays) so nothing overwrites the cloud copy unasked.
    final migrated = _settings.get(_ownerMigratedKey) == true;
    if (signedIn && dataOwner == null) {
      if (migrated) {
        _log('Sign-in choice was not finished; signing out, data kept');
        unawaited(signOut());
      } else {
        unawaited(claimLocal());
      }
    }
    if (!migrated) unawaited(_settings.put(_ownerMigratedKey, true));
    if (signedIn && !ownsLocal) {
      _log('Phone data belongs to another account; automatic backup is off');
    }
    _log(
      signedIn
          ? 'Start: signed in as ${_mask(email)} (id ${user.value?.id})'
          : 'Start: signed out',
    );
    _authSub = _db.auth.onAuthStateChange.listen((s) {
      _log(
        'Auth event: ${s.event.name}${s.session == null ? '' : ' · ${_mask(s.session?.user.email)}'}',
      );
      user.value = s.session?.user;
      if (s.session == null) lastBackupAt.value = null;
    });
    unawaited(loadConfig());
    if (signedIn) unawaited(_startupBackup());

    // Back online with changes waiting: back them up.
    _netSub = Connectivity().onConnectivityChanged.listen((r) {
      final online = r.any((c) => c != ConnectivityResult.none);
      if (online && pending.value) unawaited(_autoBackup());
    });

    // "Backs up by itself": any change to the log schedules a quiet backup.
    final supply = Get.isRegistered<SupplyService>()
        ? Get.find<SupplyService>()
        : null;
    _changes = everAll([
      tracker.profile,
      tracker.doses,
      tracker.days,
      tracker.weights,
      tracker.myFoods,
      ?supply?.purchases,
      ?supply?.packStartedAt,
    ], (_) => _scheduleAuto());

    // Settings saved straight to the box (reminders, pens count, Today
    // layout, visit date…) have no list to watch, so watch the box.
    _settingsSub = _settings.watch().listen((e) {
      if (!_phoneOnlyKeys.contains('${e.key}')) _scheduleAuto();
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _netSub?.cancel();
    _changes?.dispose();
    _settingsSub?.cancel();
    _autoTimer?.cancel();
    super.onClose();
  }

  String? get _appVersion {
    try {
      return AppInfo().version;
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------- auto backup

  void _scheduleAuto() {
    if (autoPaused || !ownsLocal || !hasLocalData) return;
    if (!pending.value) unawaited(_setPending(true));
    _autoTimer?.cancel();
    autoQueued.value = true;
    _autoTimer = Timer(_autoDelay, _autoBackup);
  }

  Future<void> _autoBackup() async {
    autoQueued.value = false;
    if (autoPaused ||
        _autoRunning ||
        busy.value ||
        !ownsLocal ||
        !hasLocalData) {
      return;
    }
    _autoRunning = true;
    try {
      await _upload();
    } catch (e) {
      // Quiet: offline or a hiccup. The next change or start tries again.
      lastFailOffline.value = _isOffline(e);
      _log('Auto backup skipped: $e');
    } finally {
      _autoRunning = false;
    }
  }

  /// On start: refresh the date, and back up if the last one is over a day old.
  Future<void> _startupBackup() async {
    await refreshBackupInfo();
    final last = lastBackupAt.value;
    if (pending.value ||
        last == null ||
        DateTime.now().difference(last) > const Duration(days: 1)) {
      await _autoBackup();
    }
  }

  // ------------------------------------------------------------------ auth

  Future<void> _initGoogle() =>
      _googleInit ??= GoogleSignIn.instance.initialize(
        clientId: Platform.isIOS ? BackendKeys.googleIosClientId : null,
        serverClientId: BackendKeys.googleWebClientId,
      );

  Future<BackendResult> signInWithGoogle() async {
    if (!ready || !BackendKeys.hasGoogle) return BackendResult.notReady;
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      _log('Google sign-in started (${Platform.operatingSystem})');
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      _log('Google account picked: ${_mask(account.email)}');
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        _log('Google returned no ID token');
        return BackendResult.failed;
      }
      final res = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final u = res.user;
      _log(
        'Signed in ✓ ${_mask(u?.email)} · id ${u?.id} · '
        'created ${u?.createdAt} · last sign-in ${u?.lastSignInAt} · '
        'session expires ${res.session?.expiresAt == null ? '-' : DateTime.fromMillisecondsSinceEpoch(res.session!.expiresAt! * 1000)}',
      );
      await refreshBackupInfo();
      _log('Cloud backup: ${lastBackupAt.value ?? 'none yet'}');
      return BackendResult.ok;
    } on GoogleSignInException catch (e) {
      _log('Google sign-in stopped: ${e.code.name}');
      return e.code == GoogleSignInExceptionCode.canceled
          ? BackendResult.cancelled
          : BackendResult.failed;
    } on SocketException {
      return BackendResult.offline;
    } catch (e) {
      _log('Google sign-in failed: $e');
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  Future<BackendResult> signIn(SocialProvider provider) =>
      provider == SocialProvider.apple ? signInWithApple() : signInWithGoogle();

  /// Sign in with Apple (iOS only; the button is hidden on Android).
  /// Supabase checks the nonce, so the token can't be replayed.
  Future<BackendResult> signInWithApple() async {
    if (!ready || !Platform.isIOS) return BackendResult.notReady;
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      _log('Apple sign-in started');
      final rawNonce = _db.auth.generateRawNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        _log('Apple returned no ID token');
        return BackendResult.failed;
      }
      final res = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      _log('Signed in ✓ ${_mask(res.user?.email)} · id ${res.user?.id}');
      // Apple sends the name only the first time; keep it on the account.
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      if (name.isNotEmpty) {
        try {
          await _db.auth.updateUser(UserAttributes(data: {'full_name': name}));
        } catch (_) {
          // Signed in anyway; the name is a nice-to-have.
        }
      }
      await refreshBackupInfo();
      return BackendResult.ok;
    } on SignInWithAppleAuthorizationException catch (e) {
      _log('Apple sign-in stopped: ${e.code.name}');
      return e.code == AuthorizationErrorCode.canceled
          ? BackendResult.cancelled
          : BackendResult.failed;
    } on SocketException {
      return BackendResult.offline;
    } catch (e) {
      _log('Apple sign-in failed: $e');
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  Future<void> signOut() async {
    if (!ready) return;
    try {
      await _db.auth.signOut();
    } catch (_) {
      // Signed out locally anyway.
    }
    try {
      await _initGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    lastBackupAt.value = null;
    _log('Signed out');
  }

  // --------------------------------------------------------------- backups

  /// Reads when the cloud copy was last saved.
  Future<void> refreshBackupInfo() async {
    final id = user.value?.id;
    if (!ready || id == null) return;
    try {
      final row = await _db
          .from('backups')
          .select('updated_at')
          .eq('user_id', id)
          .maybeSingle();
      final at = row?['updated_at'];
      lastBackupAt.value = at is String
          ? DateTime.tryParse(at)?.toLocal()
          : null;
    } catch (e) {
      _log('Backup info failed: $e');
    }
  }

  /// Replaces the cloud copy with what is on this phone.
  Future<BackendResult> backupNow() async {
    final id = user.value?.id;
    if (!ready || id == null) return BackendResult.notReady;
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      await _upload();
      return BackendResult.ok;
    } catch (e) {
      _log('Backup failed: $e');
      lastFailOffline.value = _isOffline(e);
      return lastFailOffline.value
          ? BackendResult.offline
          : BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  Future<void> _upload() async {
    final id = user.value?.id;
    if (id == null || !hasLocalData) return;
    if (!ownsLocal) throw StateError('Phone data belongs to another account');
    // Debug test data must never replace the real cloud backup.
    if (TestData.isOn) throw StateError('Test data on this phone');
    final data = tracker.backupData();
    await _db.from('backups').upsert({
      'user_id': id,
      'data': data,
      'app_version': _appVersion,
      'platform': Platform.operatingSystem,
      'size_bytes': utf8.encode(jsonEncode(data)).length,
    });
    await _setPending(false);
    lastFailOffline.value = true;
    await refreshBackupInfo();
    _log(
      'Backup saved ✓ ${(utf8.encode(jsonEncode(data)).length / 1024).toStringAsFixed(1)} KB · '
      '${tracker.doses.length} doses · ${tracker.days.length} days · ${tracker.weights.length} weigh-ins',
    );
  }

  /// Looks for this account's backup. `ok` is false when it couldn't be
  /// checked (offline or an error), so "no backup" is never assumed then.
  Future<({CloudBackup? backup, bool ok})> checkBackup() async {
    try {
      return (backup: await fetchBackup(), ok: true);
    } catch (e) {
      _log('Backup check failed: $e');
      return (backup: null, ok: false);
    }
  }

  /// The cloud copy, or null when there is none. Throws when offline.
  Future<CloudBackup?> fetchBackup() async {
    final id = user.value?.id;
    if (!ready || id == null) return null;
    final row = await _db
        .from('backups')
        .select('data, updated_at')
        .eq('user_id', id)
        .maybeSingle();
    final data = row?['data'];
    final at = row?['updated_at'];
    if (data is! Map<String, dynamic> || at is! String) return null;
    return CloudBackup(
      data: data,
      updatedAt: DateTime.tryParse(at)?.toLocal() ?? DateTime.now(),
    );
  }

  /// Replaces everything on this phone with [backup].
  Future<BackendResult> restore(CloudBackup backup) async {
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      final ok = await tracker.restoreBackup(backup.data);
      if (!ok) return BackendResult.failed;
      // The restored settings may name another owner (or none): the data
      // is now this account's, and nothing is waiting to upload.
      await claimLocal();
      await _setPending(false);
      if (Get.isRegistered<SupplyService>()) Get.find<SupplyService>().load();
      if (Get.isRegistered<NotifPrefs>()) Get.find<NotifPrefs>().load();
      _log(
        'Restored ✓ backup from ${backup.updatedAt} · ${tracker.doses.length} doses',
      );
      return BackendResult.ok;
    } catch (e) {
      _log('Restore failed: $e');
      return BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  // -------------------------------------------------------------- sign out

  /// Before signing out: put the latest changes in the cloud. True when
  /// nothing would be lost (backed up, or nothing to back up).
  Future<bool> flushBeforeSignOut() async {
    if (!ownsLocal || !hasLocalData) return true;
    if (busy.value) return false;
    busy.value = true;
    try {
      await _upload();
      return true;
    } catch (e) {
      _log('Last backup before sign-out failed: $e');
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// Signs out everywhere and clears the phone. The account's data stays
  /// in its cloud backup and comes back when they sign in again.
  Future<void> signOutAndClear() async {
    await signOut();
    await _clearPhone();
  }

  Future<void> _clearPhone() async {
    _autoTimer?.cancel();
    await tracker.deleteAll();
    pending.value = false;
    if (Get.isRegistered<SupplyService>()) Get.find<SupplyService>().load();
    if (Get.isRegistered<NotifPrefs>()) Get.find<NotifPrefs>().load();
    _log('Phone cleared');
  }

  // ---------------------------------------------------------------- delete

  /// Deletes the account and its cloud backup, signs out and clears the
  /// phone.
  Future<BackendResult> deleteAccount() async {
    if (!ready || !signedIn) return BackendResult.notReady;
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      final res = await _db.functions.invoke('delete-account');
      _log('Delete account: status ${res.status}');
      if (res.status != 200) return BackendResult.failed;
      await signOut();
      await _clearPhone();
      return BackendResult.ok;
    } catch (e) {
      _log('Delete account failed: $e');
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  // -------------------------------------------------------------- feedback

  /// Saves an idea from Me → Suggest a feature. [kind] is 'feature' or
  /// 'improvement'. Works signed out too.
  Future<BackendResult> sendFeedback({
    required String kind,
    required String message,
  }) async {
    if (!ready) return BackendResult.notReady;
    try {
      await _db.from('feedback').insert({
        'user_id': user.value?.id,
        'kind': kind,
        'message': message,
        'app_version': _appVersion,
        'platform': Platform.operatingSystem,
      });
      _log('Feedback sent ($kind)');
      return BackendResult.ok;
    } catch (e) {
      _log('Feedback failed: $e');
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    }
  }

  // ---------------------------------------------------------------- config

  /// Loads app_config rows (discount offer for now). Keeps defaults on
  /// any error.
  Future<void> loadConfig() async {
    if (!ready) return;
    try {
      final rows = await _db.from('app_config').select('key, value');
      _log('Config loaded: ${rows.map((r) => r['key']).join(', ')}');
      for (final r in rows) {
        if (r['key'] == 'app' && Get.isRegistered<AppStatusService>()) {
          Get.find<AppStatusService>().applyRemote(r['value']);
        }
        if (r['key'] == 'access' && Get.isRegistered<AccessService>()) {
          Get.find<AccessService>().applyRemote(r['value']);
        }
        if (r['key'] == 'paywall_offer' && Get.isRegistered<OfferService>()) {
          final value = r['value'];
          if (value is Map && value.isNotEmpty) {
            Get.find<OfferService>().applyRemote(value.cast<String, dynamic>());
          }
        }
      }
    } catch (e) {
      _log('Config load failed: $e');
    }
  }

  bool _isOffline(Object e) {
    final s = e.toString();
    return e is SocketException ||
        s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused');
  }
}
