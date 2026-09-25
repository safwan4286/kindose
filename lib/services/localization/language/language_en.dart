import 'languages.dart';

class LanguageEn extends Languages {
  @override
  String get appName => "Jawlyn";

  @override
  String get okayLabel => "Okay";

  @override
  String get developerModeEnabledTitle => "Developer Mode is Enabled";

  @override
  String get developerModeEnabledMessage =>
      "We’ve detected that this device has developer mode enabled. To proceed, please disable Developer Mode in your device settings.";

  @override
  String get openSettingsButtonText => "Open Settings";

  @override
  String get cameraAccessMsg =>
      "This feature uses the camera to scan documents. Camera access is currently disabled.If you’d like to use this feature, please enable camera access in Settings. Otherwise, you can cancel and continue using the app without it.";

  @override
  String get openAppSettings => "Open App Settings";

  @override
  String get cancelLabel => "Cancel";
}
