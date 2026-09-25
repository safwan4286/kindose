import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../services/get_it/get_it_setup.dart';
import '../services/local_storage/local_storage.dart';
import '../services/logs/logs.dart';

abstract class CommonMethods {
  Future<String> getUserToken() async {
    try {
      return await LocalStorage().readData(
            boxName: HiveBox.user,
            key: HiveKeys.userToken,
          ) ??
          "";
    } catch (e) {
      devPrint("error :- getUserToken ${e.toString()}");
      return "";
    }
  }

  static Future<String> getDeviceUdid() async {
    final localStorage = getIt<LocalStorage>();
    String deviceId = "";

    Future<String> getDeviceId() async {
      String identifier = "";
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          var build = await deviceInfoPlugin.androidInfo;
          identifier = build.id; //UUID for Android
        } else if (Platform.isIOS) {
          var data = await deviceInfoPlugin.iosInfo;
          identifier = data.identifierForVendor!; //UUID for iOS
        }
        devPrint("UDID $identifier");
      } on Exception {
        devPrint('Failed to get platform version');
      }
      return identifier;
    }

    String? localDeviceId = await localStorage.readData<String>(
      boxName: HiveBox.user,
      key: HiveKeys.deviceId,
    );
    if (localDeviceId?.isNotEmpty ?? false) {
      deviceId = localDeviceId ?? "";
    } else {
      deviceId = await getDeviceId();
      if (deviceId.isNotEmpty) {
        await localStorage.writeData<String>(
          boxName: HiveBox.user,
          key: HiveKeys.deviceId,
          value: deviceId,
        );
      }
    }

    return deviceId;
  }

  static void goBack() {
    if (Navigator.canPop(Get.context!)) {
      Navigator.of(Get.context!).pop();
    }
  }
}
