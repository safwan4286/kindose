import 'dart:async';

import '../core/typedefs.dart';
import 'request.dart';

class ApiQueueItem {
  /// This contains all the important data related api class such as url, header, body, and more.
  final ApiRequest request;

  /// Completer is used to whether the api process is completed or not.
  final Completer<ApiResponse> completer;

  ApiQueueItem(this.request, this.completer);
}
