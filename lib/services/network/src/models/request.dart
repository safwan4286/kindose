import 'package:kindose/services/network/src/models/scripts.dart';

import '../core/enums.dart';
import '../core/typedefs.dart';
import 'multipart_file_data.dart';

class ApiRequest {
  String url;
  final Method method;
  Map<String, String>? headers;
  final bool isDeviceIdRequired;
  final bool isTokenRequired;
  ApiResponse body;
  final Duration timeout = const Duration(seconds: 60);
  Map<String, dynamic>? params;

  /// Can pass for multipart files.
  final List<MultipartFileDataModel>? fileData;

  /// This is used to pass the error presentation type such as dialog, toast, or none.
  ErrorPresentationType errorPresentationType;

  /// Can pass when we want to show the loader. By default it will get false.
  final bool showLoader;

  /// Can pass the script in the class to call functions before some process. such as before the api call
  /// after getting the response, on getting the error.
  final ApiScripts? scripts;

  /// if session is expired then this will pass as true.
  bool sessionExpired;

  /// if developer want to call one API first before other APIs then they need to pass this to [Priority.high],
  /// otherwise it will take [Priority.low] as default.
  Priority priority;

  /// if developer want to call custom base url instead of app base url
  String? customBaseUrl;
  bool hasRetried;
  bool? isRefreshTokenRequest;

  String? businessId;

  ApiRequest({
    required this.url,
    required this.method,
    this.headers,
    this.body,
    this.fileData,
    this.errorPresentationType = ErrorPresentationType.dialog,
    this.showLoader = true,
    this.scripts,
    this.sessionExpired = false,
    this.isDeviceIdRequired = true,
    this.isTokenRequired = true,
    this.priority = Priority.low,
    this.params,
    this.customBaseUrl,
    this.hasRetried = false,
    this.isRefreshTokenRequest = false,
    this.businessId = '',
  });

  ApiRequest copyWith({
    String? url,
    Method? method,
    Map<String, String>? headers,
    bool? isDeviceIdRequired,
    bool? isTokenRequired,
    ApiResponse? body,
    Map<String, dynamic>? params,
    List<MultipartFileDataModel>? fileData,
    ErrorPresentationType? errorPresentationType,
    bool? showLoader,
    ApiScripts? scripts,
    bool? sessionExpired,
    Priority? priority,
    String? customBaseUrl,
    bool? hasRetried,
    bool? isRefreshTokenRequest,
    String? businessId,
  }) {
    return ApiRequest(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      fileData: fileData ?? this.fileData,
      errorPresentationType:
          errorPresentationType ?? this.errorPresentationType,
      showLoader: showLoader ?? this.showLoader,
      scripts: scripts ?? this.scripts,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      isDeviceIdRequired: isDeviceIdRequired ?? this.isDeviceIdRequired,
      isTokenRequired: isTokenRequired ?? this.isTokenRequired,
      priority: priority ?? this.priority,
      params: params ?? this.params,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      hasRetried: hasRetried ?? this.hasRetried,
      isRefreshTokenRequest:
          isRefreshTokenRequest ?? this.isRefreshTokenRequest,
      businessId: businessId ?? this.businessId,
    );
  }
}
