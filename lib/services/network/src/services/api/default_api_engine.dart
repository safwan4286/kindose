import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../logs/logs.dart';
import '../../core/common_values.dart';
import '../../core/dialogs.dart';
import '../../core/enums.dart';
import '../../core/typedefs.dart';
import '../../models/multipart_file_data.dart';
import '../../models/queue_item.dart';
import '../../models/request.dart';
import '../encryption/encryption.dart';
import '../internet/internet_service.dart';
import '../network_service.dart';
import 'api_service.dart';

class DefaultApiEngine {
  static DefaultApiEngine? _instance;

  DefaultApiEngine._internal();

  static DefaultApiEngine get instance {
    _instance ??= DefaultApiEngine._internal();
    return _instance!;
  }

  /// This contains the queue of API request given by apps. It will call it one by one.
  final List<ApiQueueItem> _queue = [];

  /// This is used to know whether the API processing is completed or not.
  bool _isProcessing = false;

  bool get isApiCalling => _isProcessing;

  /// This method is the starting point of the API call.
  Future<ApiResponse> call({required ApiRequest request}) async {
    // _isProcessing = false;

    if (request.showLoader) {
      NetworkService.instance.apiModel?.progressIndicator?.showLoader();
    }

    final completer = Completer<ApiResponse>();

    if (request.sessionExpired || request.priority == Priority.high) {
      _queue.insert(0, ApiQueueItem(request, completer));
      _isProcessing = false;
    } else {
      _queue.add(ApiQueueItem(request, completer));
    }

    if (!_isProcessing) {
      _isProcessing = true;
      _processQueue();
    }

    if (request.showLoader) {
      NetworkService.instance.apiModel?.progressIndicator?.hideLoader();
    }
    return completer.future;
  }

  /// [_processQueue] is used to call the API based to given request and [_queue].
  Future<void> _processQueue() async {
    AesTreasure aesTreasure = AesTreasure(
      key: Encryption.instance.getRandomString(32),
      iv: Encryption.instance.getRandomString(16),
    );

    /// this will calculate the time the api takes
    Stopwatch stopwatch = Stopwatch()..start();

    // if queue is empty then this method will break
    while (_queue.isNotEmpty) {
      ApiQueueItem queueItem = _queue.first;
      ApiRequest request = queueItem.request;
      Completer<ApiResponse> completer = queueItem.completer;

      // if (request.showLoader) {
      //   NetworkService.instance.apiModel?.progressIndicator?.showLoader();
      // }

      late http.Client client;
      // if (request.isCertificateRequired &&
      //     BuildVariantService.instance.currentEnvironment ==
      //         Environment.production) {
      //   client = CertificatePinning.instance.client;
      // } else {
      //   client = http.Client();
      // }

      client = http.Client();

      // set headers
      if (request.headers != null) {
        request.headers!.addAll(
          await CommonValues.commonHeaders(
            isDeviceIdRequired: request.isDeviceIdRequired,
            businessID: request.businessId ?? "",
          ),
        );
      } else {
        request.headers = <String, String>{};
        request.headers!.addAll(
          await CommonValues.commonHeaders(
            isDeviceIdRequired: request.isDeviceIdRequired,
            businessID: request.businessId ?? "",
          ),
        );
      }
      devPrint(
        "${request.url} | Method | ${json.encode(request.method.name.toUpperCase())}",
      );

      devPrint("${request.url} | Headers | ${json.encode(request.headers)}");

      // set body
      if (request.body != null) {
        request.body!.addAll(await CommonValues.body());
      } else {
        request.body = <String, dynamic>{};
        // request.body?.addAll(await CommonValues.body());
      }
      if (Encryption.instance.status && request.body != null) {
        devPrint(
          "${request.url} | Original Body | ${json.encode(request.body)}",
        );
        String data = await Encryption.instance.encryptData(
          data: '''${(request.body)}''',
          aesTreasure: aesTreasure,
        );
        request.body!.clear();
        request.body!["jsonData"] = data;
        devPrint(
          "${request.url} | Encrypted Body | ${json.encode(request.body)}",
        );
      } else {
        devPrint("${request.url} | Body | ${json.encode(request.body)}");
        devPrint("${request.url} | Params | ${json.encode(request.params)}");
      }

      if (request.scripts?.preApiCall != null) {
        await request.scripts!.preApiCall!(request);
      }

      if (await InternetService.checkInternetIsAvailable()) {
        try {
          switch (request.method) {
            case Method.get:
              Uri uri = Uri.parse(request.url);
              Uri finalUri = uri.replace(queryParameters: request.params);

              http.Response response = await client.get(
                finalUri,
                headers: request.headers,
              );
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
            case Method.post:
              http.Response response = await client.post(
                Uri.parse(request.url),
                headers: request.headers,
                body: jsonEncode(request.body),
              );
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
            case Method.put:
              http.Response response = await client.put(
                Uri.parse(request.url),
                headers: request.headers,
                body: jsonEncode(request.body),
              );
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
            case Method.delete:
              http.Response response = await client.delete(
                Uri.parse(request.url),
                headers: request.headers,
                body: jsonEncode(request.body),
              );
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
            case Method.multipart:
              http.MultipartRequest multipartRequest = http.MultipartRequest(
                "POST",
                Uri.parse(request.url),
              );

              for (MultipartFileDataModel file in request.fileData ?? []) {
                multipartRequest.files.add(
                  await http.MultipartFile.fromPath(
                    file.parameterName,
                    file.filePath,
                  ),
                );
              }

              for (var entry in request.body!.entries) {
                multipartRequest.fields[entry.key] = entry.value.toString();
              }

              multipartRequest.headers.addAll(request.headers ?? {});
              late http.StreamedResponse streamedResponse;
              // if (request.isCertificateRequired) {
              //   streamedResponse = await client.send(multipartRequest);
              // } else {
              //   streamedResponse = await multipartRequest.send();
              // }
              streamedResponse = await multipartRequest.send();

              // await setupStreamListener(streamedResponse);
              http.Response response = await http.Response.fromStream(
                streamedResponse,
              );
              var instance = await SharedPreferences.getInstance();

              await instance.setBool("multipart", false);
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
            default:
              http.Response response = await client.post(
                Uri.parse(request.url),
                headers: request.headers,
                body: jsonEncode(request.body),
              );
              await ApiService.instance.evaluateResponse(
                response: response,
                request: request,
                completer: completer,
                aesTreasure: aesTreasure,
              );
              break;
          }
        } catch (e, stacktrace) {
          devPrint(
            'API call failed: $e with \n Stacktrace ${stacktrace.toString()}',
          );
          _onError(request);
        }
      } else {
        await Dialogs.def(
          message:
              "Your phone is not connected to the Internet. Please check your data/wifi connection and try again.",
          barrierDismissible: false,
          hideSecondIcon: true,
          buttonText: "Retry",
        );
        await _processQueue();
      }

      if (_queue.isNotEmpty) {
        _queue.removeAt(0);
        stopwatch.stop();
        devPrint("${request.url} | Time | ${stopwatch.elapsedMilliseconds} ms");
      }

      if (request.sessionExpired) {
        // Assigned true because we have to want till the login pin animation
        // After the login pin animation completion, it will get back to the previous screen
        // and process the last APIs.
        _isProcessing = true;
        break;
      }
    }

    _isProcessing = false;
  }

  Future<void> _onError(ApiRequest request, {ApiResponse response}) async {
    if (request.scripts?.onError == null) {
      // clearQueue();
      await Dialogs.def(message: "Server Error");
    } else {
      await request.scripts!.onError!(request, response);
    }

    if (request.scripts?.postError != null) {
      await request.scripts!.postError!(request, response);
    }
  }

  void clearQueue() {
    _queue.clear();
    _isProcessing = false;
  }
}
