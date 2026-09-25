import 'dart:async';

import '../core/typedefs.dart';
import 'request.dart';

class ApiScripts {
  /// Can call before the api call to do modification in url, body, headers, or change the files for multipart.
  final Future<void> Function(ApiRequest request)? preApiCall;

  /// Can call after we get the response from the api and when it is processed in json without getting any errors.
  final Future<void> Function(
    ApiRequest request,
    Map<String, dynamic> response, [
    Completer<ApiResponse>? completer,
  ])? preCheckResponse;

  /// Can call when you want to specify the the error code that is not available in the check response switch case.
  final Future<void> Function(
    ApiRequest request,
    Map<String, dynamic> response,
    Completer<ApiResponse> completer,
  )? onUnknownErrorCode;

  /// Can call when the unexpected error occured in the API.
  final Future<void> Function(ApiRequest request, [ApiResponse response])?
      onError;

  /// Can call after the error if you want to return the custom response.
  final Future<void> Function(ApiRequest request, [ApiResponse response])?
      postError;

  ApiScripts({
    this.preApiCall,
    this.preCheckResponse,
    this.onUnknownErrorCode,
    this.onError,
    this.postError,
  });
}
