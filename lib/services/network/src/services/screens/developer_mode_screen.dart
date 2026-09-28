import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../resources/colors.dart';
import '../../../../../resources/common_methods.dart';
import '../../../../../resources/fonts.dart';
import '../../../../localization/language/languages.dart';
import '../../../../logs/logs.dart';
import '../../../../responsiveness/device_manager.dart';

class DeveloperModeControl {
  static final DeveloperModeControl _instance =
      DeveloperModeControl._internal();

  factory DeveloperModeControl() {
    return _instance;
  }

  DeveloperModeControl._internal();

  bool _isShowing = false;

  Future<void> show() async {
    if (!_isShowing) {
      DeveloperModeControl()._isShowing = true;
      await Get.dialog(
        barrierDismissible: false,
        useSafeArea: false,
        const _DeveloperModeScreen(),
      );
    }
  }

  Future<void> hide() async {
    if (_isShowing) {
      DeveloperModeControl()._isShowing = false;
      // Get.back();
      CommonMethods.goBack();
    }
  }
}

class _DeveloperModeScreen extends StatelessWidget {
  const _DeveloperModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String title = Languages.of(context).developerModeEnabledTitle;
    String errorMessage = Languages.of(context).developerModeEnabledMessage;
    String buttonText = Languages.of(context).openSettingsButtonText;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: WillPopScope(
        onWillPop: () async => Future.value(false),
        child: Container(
          padding: EdgeInsets.all(20.0.sp),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning_rounded, color: Colors.yellow, size: 70.0.sp),
              Padding(
                padding: EdgeInsets.only(top: 10.0.sp),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: Fonts.poppinsExtraBold,
                    fontSize: 20.0.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5.0.sp),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    fontFamily: Fonts.poppinsSemiBold,
                    fontSize: 15.0.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0.sp),
                child: ElevatedButton(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      const intent = AndroidIntent(
                        action:
                            'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
                      );
                      intent.launch();
                    } else {
                      devPrint("This feature is only available on Android.");
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: 14.0.sp,
                        vertical: 8.0.sp,
                      ),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0.sp),
                      ),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontFamily: Fonts.poppinsBold,
                      fontSize: 14.0.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _launchEmail(String email) async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=I have problem with opening the app.&body=I cannot open the app as I am seeing this message - "There\'s a problem with your app. Please contact support at Selcom for help."',
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw 'Could not launch $emailUri';
  }
}
