import 'dart:developer';

import 'package:flutter/foundation.dart';

void devPrint(
  String message, {
  String? identity,
}) {
  if (identity != null) {
    identity = "[$identity] ";
  } else {
    identity = "";
  }

  if (kDebugMode) {
    log("[${_printCurrentTime()}] $identity$message");
  }
}

String _printCurrentTime() {
  DateTime now = DateTime.now();
  String formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}:'
      '${now.microsecond.toString().padLeft(6, '0')}';
  return formattedTime;
}
