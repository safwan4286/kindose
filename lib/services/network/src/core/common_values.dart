import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';


import '../../../../resources/common_methods.dart';
import '../../../../resources/constants.dart';
import '../../../device_token/device_info.dart';
import '../../../get_it/get_it_setup.dart';
import '../services/network_service.dart';
import 'constants.dart';

class CommonValues {
  static Future<Map<String, String>> commonHeaders({
    bool isDeviceIdRequired = true,
    bool isTokenRequired = true,
    String businessID = '',
  }) async {
    Map<String, String> headers = {};
    headers.addAll(NetworkService.instance.apiModel?.defaultHeaders ?? {});

    headers[Body.deviceId] = await CommonMethods.getDeviceUdid();

    if (isTokenRequired) {
      // String token = await getIt<UserController>().getUserToken();
      // headers[Headers.AUTHORIZATION] = "Bearer $token";
    }

    headers[Body.fcmToken] = DeviceInfo().token;

    headers[Body.deviceType] = Platform.isAndroid ? "android" : "ios";

    headers[Body.platform] = Platform.isAndroid
        ? "android"
        : Platform.isIOS
        ? "ios"
        : "";

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    headers[Body.appVersion] = packageInfo.version;



    return headers;
  }

  static Future<Map<String, dynamic>> params() async {
    Map<String, dynamic> params = emptyMap;

    params.addAll(NetworkService.instance.apiModel?.defaultParams ?? {});

    return params;
  }

  static Future<Map<String, dynamic>> body() async {
    Map<String, dynamic> body = {};

    body.addAll(NetworkService.instance.apiModel?.defaultBody ?? {});

    return body;
  }
}
