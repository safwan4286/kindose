import 'package:package_info_plus/package_info_plus.dart';

/// App version and package name, read once at start (main → [get]).
class AppInfo {
  static final AppInfo _instance = AppInfo._internal();

  factory AppInfo() => _instance;

  AppInfo._internal();

  late PackageInfo _package;

  Future<void> get() async {
    _package = await PackageInfo.fromPlatform();
  }

  PackageInfo get package => _package;

  /// "1.0.0" (without the build number).
  String get version => _package.version;
}
