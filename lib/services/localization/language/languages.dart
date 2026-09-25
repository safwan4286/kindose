import 'package:flutter/material.dart';

abstract class Languages {
  static Languages of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages) ??
        Languages.of(context);
  }

  String get appName;

  String get okayLabel;

  String get developerModeEnabledTitle;

  String get developerModeEnabledMessage;

  String get openSettingsButtonText;

  String get cameraAccessMsg;

  String get openAppSettings;

  String get cancelLabel;
}
