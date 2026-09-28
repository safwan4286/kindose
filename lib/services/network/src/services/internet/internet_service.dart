import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../../../../resources/common_methods.dart';
import '../../../../logs/logs.dart';
import '../../core/dialogs.dart';

class InternetService {
  static InternetService? _instance;

  InternetService._internal();

  static InternetService get instance {
    _instance ??= InternetService._internal();
    return _instance!;
  }

  final connectivity = Connectivity();

  bool _isDialogShowing = false;

  bool isAppOpenForTheFirstTime = true;

  void listen() {
    isAppOpenForTheFirstTime = true;

    connectivity.onConnectivityChanged.listen((result) {
      devPrint("connectivity status: $result");
      bool isDeviceConnectedWithInternet =
          result.first == ConnectivityResult.mobile ||
          result.first == ConnectivityResult.wifi;
      devPrint("Internet connection status: $isDeviceConnectedWithInternet");
      if (isDeviceConnectedWithInternet) {
        internetConnectionAvailableToast();
      } else {
        noInternetConnectionDialog();
      }
    });
  }

  Future<void> checkInternet({
    required Future<void> Function() success,
    Future<void> Function()? failure,
  }) async {
    List<ConnectivityResult> result = await connectivity.checkConnectivity();
    for (var data in result) {
      print(data);
    }

    if (result.first == ConnectivityResult.mobile ||
        result.first == ConnectivityResult.wifi) {
      await success();
    } else {
      if (failure != null) {
        failure();
      } else {
        noInternetConnectionDialog();
      }
    }
  }

  // Future<bool> isInternetAvailable() async {
  // bool result = await InternetConnectionChecker.instance.hasConnection;
  // if (result == true) {
  //   return true;
  // } else {
  //   return false;
  // }
  // }

  static Future<bool> checkInternetIsAvailable() async {
    try {
      List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity();
      if (connectivityResult.first == ConnectivityResult.mobile) {
        return true;
      } else if (connectivityResult.first == ConnectivityResult.wifi) {
        return true;
      } else if (connectivityResult.first == ConnectivityResult.ethernet) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  void noInternetConnectionDialog() {
    if (!_isDialogShowing && !isAppOpenForTheFirstTime) {
      if (Get.isSnackbarOpen) {
        // Get.back();
        CommonMethods.goBack();
      }

      _isDialogShowing = true;
      Dialogs.def(
        message:
            "Your phone is not connected to the Internet. Please check your data/wifi connection and try again.",
        hideSecondIcon: true,
        buttonText: "Retry",
      ).then((value) => _isDialogShowing = false);
    }
  }

  void internetConnectionAvailableToast() {
    if (_isDialogShowing) {
      // Get.back();
      CommonMethods.goBack();
    }

    if (!isAppOpenForTheFirstTime) {
      Dialogs.def(message: "Internet is connected");
    }
  }
}
