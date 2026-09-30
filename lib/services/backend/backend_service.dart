import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../resources/backend_keys.dart';
import '../app_info.dart';
import '../offers/offer_service.dart';
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
  Timer? _autoTimer;
  bool _autoRunning = false;

  /// Set while the user decides between this phone and a cloud backup, so
  /// an automatic backup can't overwrite the cloud copy first.
  bool autoPaused = false;

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

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    if (!ready) return;
    user.value = _db.auth.currentUser;
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
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _changes?.dispose();
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
    if (autoPaused || !signedIn || tracker.profile.value == null) return;
    _autoTimer?.cancel();
    _autoTimer = Timer(_autoDelay, _autoBackup);
  }

  Future<void> _autoBackup() async {
    if (autoPaused ||
        _autoRunning ||
        busy.value ||
        !signedIn ||
        tracker.profile.value == null) {
      return;
    }
    _autoRunning = true;
    try {
      await _upload();
    } catch (e) {
      // Quiet: offline or a hiccup. The next change or start tries again.
      _log('Auto backup skipped: $e');
    } finally {
      _autoRunning = false;
    }
  }

  /// On start: refresh the date, and back up if the last one is over a day old.
  Future<void> _startupBackup() async {
    await refreshBackupInfo();
    final last = lastBackupAt.value;
    if (last == null ||
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
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    } finally {
      busy.value = false;
    }
  }

  Future<void> _upload() async {
    final id = user.value?.id;
    if (id == null || tracker.profile.value == null) return;
    final data = tracker.backupData();
    await _db.from('backups').upsert({
      'user_id': id,
      'data': data,
      'app_version': _appVersion,
      'platform': Platform.operatingSystem,
      'size_bytes': utf8.encode(jsonEncode(data)).length,
    });
    await refreshBackupInfo();
    _log(
      'Backup saved ✓ ${(utf8.encode(jsonEncode(data)).length / 1024).toStringAsFixed(1)} KB · '
      '${tracker.doses.length} doses · ${tracker.days.length} days · ${tracker.weights.length} weigh-ins',
    );
  }

  /// The cloud copy, or null when there is none.
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
      if (Get.isRegistered<SupplyService>()) Get.find<SupplyService>().load();
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

  // ---------------------------------------------------------------- delete

  /// Deletes the account and its cloud backup. The phone's data is left to
  /// the caller (Me → Delete all my data clears it).
  Future<BackendResult> deleteAccount() async {
    if (!ready || !signedIn) return BackendResult.notReady;
    if (busy.value) return BackendResult.failed;
    busy.value = true;
    try {
      final res = await _db.functions.invoke('delete-account');
      _log('Delete account: status ${res.status}');
      if (res.status != 200) return BackendResult.failed;
      await signOut();
      return BackendResult.ok;
    } catch (e) {
      _log('Delete account failed: $e');
      return _isOffline(e) ? BackendResult.offline : BackendResult.failed;
    } finally {
      busy.value = false;
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
