import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';

abstract class Functions {
  static Future<void> openBottomsheet({
    required Widget body,
    bool doAnimation = true,
  }) async {
    await Get.bottomSheet(
      body,
      enterBottomSheetDuration: doAnimation
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      exitBottomSheetDuration: doAnimation
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      elevation: 0,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  static Future<dynamic> openDialog({
    required Widget body,
    bool canCloseDialog = true,
  }) async {
    if (Get.isDialogOpen ?? false) return;

    return await Get.dialog(
      PopScope(canPop: canCloseDialog, child: body),
      barrierDismissible: canCloseDialog,
    );
  }

  // static Future<dynamic> openDialog({
  //   required Widget body,
  //   bool canCloseDialog = true,
  // }) async {
  //   // getIt<BaseController>().isBlurApplied.value = true;
  //   final result = await Get.dialog(
  //     PopScope(canPop: canCloseDialog, child: body
  //         // .animate()
  //         // .fade(duration: 400.ms, curve: Curves.fastOutSlowIn)
  //         // .scale(duration: 400.ms, curve: Curves.fastOutSlowIn),
  //         ),
  //   );
  //   // getIt<BaseController>().isBlurApplied.value = false;
  //   return result;
  // }

  static Future<void> openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<DateTime?> openDatePicker({
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? initialDate,
  }) async {
    return await showDatePicker(
      context: Get.context!,
      firstDate:
          firstDate ?? DateTime.now().subtract(const Duration(days: 100)),
      initialDate: initialDate,
      lastDate: lastDate ?? DateTime.now(),
    );
  }

  static Future<TimeOfDay> openTimePicker({int? hour, int? minute}) async {
    return await showTimePicker(
          context: Get.context!,
          initialTime: TimeOfDay(hour: hour ?? 0, minute: minute ?? 0),
          builder: (context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        ) ??
        const TimeOfDay(hour: 00, minute: 00);
  }

  static void showGeneralToastMessage({
    String? message,
    Duration? duration,
    SnackPosition? snackPosition,
    Color? color,
  }) {
    if (Get.isSnackbarOpen) {
      return;
    }
    Get.showSnackbar(
      GetSnackBar(
        isDismissible: false,
        snackStyle: SnackStyle.FLOATING,
        snackPosition: snackPosition ?? SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        borderRadius: 10.0,
        duration: duration ?? const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 800),
        forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
        reverseAnimationCurve: Curves.easeOutCubic,
        backgroundColor: color ?? AppColors.primary,
        messageText: Text(
          message ?? "",
          style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  static Future<void> dismissKeyboard() async {
    final focus = FocusScope.of(Get.context!);
    if (!focus.hasPrimaryFocus && focus.hasFocus) {
      focus.unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static String formatTimeDifference(DateTime utcServerTime) {
    DateTime getUtcTime(DateTime dateTime) {
      DateTime utcTime = dateTime.subtract(dateTime.timeZoneOffset);
      return utcTime;
    }

    DateTime currentUtcTime = getUtcTime(DateTime.now());

    utcServerTime = DateTime(
      utcServerTime.year,
      utcServerTime.month,
      utcServerTime.day,
      utcServerTime.hour,
      utcServerTime.minute,
      utcServerTime.second - 16,
    );
    currentUtcTime = DateTime(
      currentUtcTime.year,
      currentUtcTime.month,
      currentUtcTime.day,
      currentUtcTime.hour,
      currentUtcTime.minute,
      currentUtcTime.second,
    );

    Duration difference = currentUtcTime.difference(utcServerTime);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds.abs()}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes.abs()}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours.abs()}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays.abs()}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor().abs()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor().abs()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor().abs()}y ago';
    }
  }
}
