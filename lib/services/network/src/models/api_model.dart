import '../core/constants.dart';
import '../core/enums.dart';
import 'api_progress_indicator.dart';
import 'build_variant_model.dart';

class ApiModel {
  ApiModel({
    required this.appName,
    this.apiType = ApiType.def,
    this.defaultHeaders = const <String, String>{},
    this.defaultParams = emptyMap,
    this.defaultBody = emptyMap,
    this.encryptionEnabled = false,
    required this.buildVariants,
    this.progressIndicator,
  }) {
    progressIndicator ??= defaultProgressIndicator;
  }

  final String appName;

  final ApiType apiType;

  final Map<String, String> defaultHeaders;
  final Map<String, dynamic> defaultParams;
  final Map<String, dynamic> defaultBody;

  final bool encryptionEnabled;

  final BuildVariants buildVariants;

  ApiProgressIndicator? progressIndicator;
}
