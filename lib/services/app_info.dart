import 'package:package_info_plus/package_info_plus.dart';

import 'network/src/services/build_variant/build_variants_service.dart';

class AppInfo {
  static final AppInfo _instance = AppInfo._internal();

  factory AppInfo() {
    return _instance;
  }

  AppInfo._internal();

  Future<void> get() async {
    await _getPackageInfo();
    _getBuildType();
  }

  late PackageInfo _package;

  PackageInfo get package => _package;
  String get version => _package.version;

  Future<void> _getPackageInfo() async {
    _package = await PackageInfo.fromPlatform();
  }

  late BuildType _buildType;

  BuildType get buildType => _buildType;

  bool get isPublicVersion =>
      buildType == BuildType.LIVE &&
      BuildVariantService.instance.currentEnvironment == Environment.production;

  /// It is based on [PackageNames] that are given.
  void _getBuildType() {
    String packageName = package.packageName;

    if (packageName == PackageNames.androidDev ||
        packageName == PackageNames.iosDev) {
      _buildType = BuildType.TESTING;
    } else if (packageName == PackageNames.androidLive ||
        packageName == PackageNames.iosLive) {
      _buildType = BuildType.LIVE;
    } else {
      _buildType = BuildType.UNKNOWN;
    }
  }
}

enum BuildType { TESTING, LIVE, UNKNOWN }

class PackageNames {
  /// TODO : Add package names
  static const String androidDev = "";
  static const String iosDev = "";
  static const String androidLive = "";
  static const String iosLive = "";
}
