import 'dart:async';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';

import '../local_storage/local_storage.dart';
import '../logs/logs.dart';

class DeviceInfo {
  static final DeviceInfo _instance = DeviceInfo._internal();

  factory DeviceInfo() => _instance;

  DeviceInfo._internal();

  late AndroidDeviceInfo _android;
  late IosDeviceInfo _ios;

  AndroidDeviceInfo? get android => Platform.isAndroid ? _android : null;

  IosDeviceInfo? get ios => Platform.isIOS ? _ios : null;

  late String _token;
  late String _udid;

  String get token => _token;

  String get udid => _udid;

  bool get isAndroid => Platform.isAndroid;
  bool get isIos => Platform.isIOS;

  bool get isPhysicalDevice {
    if (kDebugMode) {
      return true;
    }

    if (Platform.isAndroid) return android?.isPhysicalDevice ?? false;
    if (Platform.isIOS) return ios?.isPhysicalDevice ?? false;
    return false;
  }

  Future<void> get() async {
    try {
      if (Platform.isAndroid) {
        _android = await DeviceInfoPlugin().androidInfo;
      } else if (Platform.isIOS) {
        _ios = await DeviceInfoPlugin().iosInfo;
      }

      _token = await getToken(freshToken: false, recursive: false);
      devPrint("token $_token");

      _udid = await getUdid();
    } catch (e) {
      devPrint('Error in get(): $e');
    }
  }

  Future<String> _getFreshToken({
    required bool freshToken,
    required bool recursive,
  }) async {
    try {
      String? freshDeviceToken = await FirebaseMessaging.instance.getToken();
      if (freshDeviceToken?.isNotEmpty ?? false) {
        await LocalStorage().writeData<String>(
          boxName: HiveBox.commonBox,
          key: HiveKeys.deviceToken,
          value: freshDeviceToken ?? "",
        );
        return freshDeviceToken ?? "";
      } else {
        if (recursive) {
          return await _getFreshToken(
            recursive: recursive,
            freshToken: freshToken,
          );
        } else {
          return "";
        }
      }
    } catch (e) {
      devPrint("getDeviceToken Exception: $e");
      if (recursive) {
        return await _getFreshToken(
          freshToken: freshToken,
          recursive: recursive,
        );
      } else {
        return "";
      }
    }
  }

  Future<String> _getLocalToken() async {
    var localToken = await LocalStorage().readData<String>(
      boxName: HiveBox.commonBox,
      key: HiveKeys.deviceToken,
    );

    localToken = localToken ?? "";

    _token = localToken;

    return localToken;
  }

  Future<String> getToken({
    required bool freshToken,
    required bool recursive,
  }) async {
    String deviceToken = "";

    if (freshToken) {
      deviceToken = await _getFreshToken(
        recursive: recursive,
        freshToken: freshToken,
      );
      if (deviceToken.isEmpty) {
        deviceToken = await _getLocalToken();
      }
    } else {
      deviceToken = await _getLocalToken();
      if (deviceToken.isEmpty) {
        deviceToken = await _getFreshToken(
          recursive: recursive,
          freshToken: freshToken,
        );
      }
    }

    _token = deviceToken;

    return deviceToken;
  }

  Future<String> getUdid() async {
    try {
      String? localIdentifier = await LocalStorage().readData<String>(
        boxName: HiveBox.commonBox,
        key: HiveKeys.uniqueDeviceId,
      );

      if (localIdentifier?.isNotEmpty ?? false) return localIdentifier!;

      String identifier = "";
      if (Platform.isAndroid) {
        identifier = await const AndroidId().getId() ?? "";
      } else if (Platform.isIOS) {
        identifier = ios?.identifierForVendor ?? "";
      }

      if (identifier.isNotEmpty) {
        await LocalStorage().writeData<String>(
          boxName: HiveBox.commonBox,
          key: HiveKeys.uniqueDeviceId,
          value: identifier,
        );
      }

      devPrint("UDID $identifier");
      return identifier;
    } catch (e) {
      devPrint('Failed to get UDID: $e');
      return "";
    }
  }
}
