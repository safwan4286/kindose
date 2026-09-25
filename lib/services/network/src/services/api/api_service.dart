// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kindose/services/network/src/services/api/sequential_api_engine.dart';

import '../../../../../controllers/user_controller.dart';
import '../../../../../resources/common_methods.dart';
import '../../../../../resources/end_points.dart';
import '../../../../get_it/get_it_setup.dart';
import '../../../../logs/logs.dart';
import '../../../../progress_indicator/loader.dart';
import '../../core/common_values.dart';
import '../../core/dialogs.dart';
import '../../core/enums.dart';
import '../../core/typedefs.dart';
import '../../models/request.dart';
import '../build_variant/build_variants_service.dart';
import '../encryption/encryption.dart';
import '../network_service.dart';
import 'default_api_engine.dart';

class ApiService {
  static ApiService? _instance;

  ApiService._internal();

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  /// This method is the starting point of the API call.
  Future<ApiResponse> call({required ApiRequest request}) async {
    if (NetworkService.instance.apiModel != null) {
      ApiResponse response;
      request.url =
          ((request.customBaseUrl?.isNotEmpty ?? false)
              ? (request.customBaseUrl ?? "")
              : BuildVariantService.instance.baseUrl) +
          request.url;
      switch (NetworkService.instance.apiModel?.apiType) {
        case ApiType.def:
          response = await DefaultApiEngine.instance.call(request: request);
          break;
        case ApiType.sequential:
          response = await SequentialApiEngine.instance.call(request: request);
          break;
        default:
          response = await DefaultApiEngine.instance.call(request: request);
      }

      return response;
    }

    return null;
  }

  /// This method is used to check whether the API response is correct or not
  Future<void> evaluateResponse({
    required http.Response response,
    required ApiRequest request,
    required AesTreasure aesTreasure,
    required Completer<ApiResponse> completer,
  }) async {
    ApiResponse? responseMap;

    devPrint("${request.url} | Status Code | ${response.statusCode}");

    try {
      if (Encryption.instance.status) {
        String decryptedResponse = await Encryption.instance.aesDecrypt(
          data: response.body,
          aesTreasure: aesTreasure,
        );
        devPrint("${request.url} | Encrypted Response | ${response.body}");
        devPrint("${request.url} | Decrypted Response | $decryptedResponse");
        responseMap = json.decode(decryptedResponse);
      } else {
        devPrint("${request.url} | Response | ${response.body}");
        responseMap = json.decode((response.body));
      }

      // await UpdateController().handleVersionFromApi(responseMap);
    } catch (e) {
      devPrint("Response json.decode error: $e");
    }

    if (request.scripts?.preCheckResponse != null && responseMap != null) {
      await request.scripts!.preCheckResponse!(request, responseMap, completer);
    }

    switch (response.statusCode) {
      case 200:
        // Check for custom status codes in response body
        final customStatusCode = responseMap?["status_code"];

        if (customStatusCode == 600) {
          Loader.instance.hide();
          // await CommonMethods.cupertinoPush(BuyPremiumScreen());

          if (!completer.isCompleted) {
            completer.complete(responseMap);
          }
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }
        break;

      case 401:
        await _handle401(
          request: request,
          responseMap: responseMap,
          completer: completer,
          aesTreasure: aesTreasure,
        );
        return;

      case 400:
        Loader.instance.hide();
        await Dialogs.def(
          message: responseMap?["message"] ?? "Bad Request",
          barrierDismissible: false,
          hideSecondIcon: true,
        );
        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }
        break;

      case 600:
        Loader.instance.hide();
        // await CommonMethods.cupertinoPush(BuyPremiumScreen());

        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }
        break;

      case 500:
        devPrint('Server error: ${response.statusCode}');
        await _onError(request, responseMap);
        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }
        break;

      default:
        devPrint('API failed: ${response.statusCode}');
        await _onError(request, responseMap);
        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }
        break;
    }
  }

  /// HANDLE 401 - Better handling
  Future<void> _handle401({
    required ApiRequest request,
    required Map<String, dynamic>? responseMap,
    required Completer<ApiResponse> completer,
    required AesTreasure aesTreasure,
  }) async {
    devPrint("🔐 401 Unauthorized for: ${request.url}");

    // If this request already tried to refresh, logout
    if (request.hasRetried) {
      devPrint("❌ Already retried. Logging out.");
      if (!completer.isCompleted) {
        completer.complete(responseMap);
      }
      await _logout();
      return;
    }

    // If currently refreshing, queue this request
    if (_isRefreshing) {
      devPrint("⏳ Token refresh in progress. Queuing request.");
      _pendingRequests.add(
        _PendingRequest(
          request: request,
          completer: completer,
          aesTreasure: aesTreasure,
        ),
      );
      return;
    }

    // Start token refresh
    _isRefreshing = true;

    try {
      devPrint("🔄 Starting token refresh...");
      final refreshed = await _refreshTokenDirect();

      if (!refreshed) {
        devPrint("❌ Token refresh failed. Logging out.");

        // Complete all pending requests
        if (!completer.isCompleted) {
          completer.complete(responseMap);
        }

        final pendingCopy = List<_PendingRequest>.from(_pendingRequests);
        for (final pending in pendingCopy) {
          if (!pending.completer.isCompleted) {
            pending.completer.complete(responseMap);
          }
        }
        _pendingRequests.clear();

        await _logout();
        return;
      }

      devPrint("✅ Token refreshed successfully. Retrying requests.");

      // Small delay for token propagation
      await Future.delayed(Duration(milliseconds: 100));

      // Retry current request
      devPrint("🔄 Retrying original request: ${request.url}");
      await _retryRequest(request, completer, aesTreasure);

      // Retry all pending requests
      final pendingCopy = List<_PendingRequest>.from(_pendingRequests);
      _pendingRequests.clear();

      devPrint("🔄 Retrying ${pendingCopy.length} pending requests...");
      for (final pending in pendingCopy) {
        await _retryRequest(
          pending.request,
          pending.completer,
          pending.aesTreasure,
        );
      }

      devPrint("✅ All retries completed");
    } catch (e) {
      devPrint("❌ Token refresh exception: $e");

      if (!completer.isCompleted) {
        completer.complete(responseMap);
      }

      final pendingCopy = List<_PendingRequest>.from(_pendingRequests);
      for (final pending in pendingCopy) {
        if (!pending.completer.isCompleted) {
          pending.completer.complete(responseMap);
        }
      }
      _pendingRequests.clear();

      await _logout();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Retry a single request with NEW token
  Future<void> _retryRequest(
    ApiRequest request,
    Completer<ApiResponse> completer,
    AesTreasure aesTreasure,
  ) async {
    try {
      devPrint("🔄 Retrying: ${request.url}");
      devPrint("🔍 Completer completed? ${completer.isCompleted}");

      final userController = getIt<UserController>();
      final newAccessToken = userController.userData?.value?.accessToken;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        devPrint("❌ No access token available after refresh!");
        if (!completer.isCompleted) {
          completer.complete({'status_code': 401, 'message': 'No token'});
        }
        return;
      }

      devPrint("🔑 Using new token: ${newAccessToken.substring(0, 20)}...");

      final client = http.Client();

      final headers = await CommonValues.commonHeaders(
        isDeviceIdRequired: request.isDeviceIdRequired,
      );

      devPrint("🔑 Retry headers Authorization: ${headers['Authorization']}");

      http.Response response;

      switch (request.method) {
        case Method.get:
          Uri uri = Uri.parse(request.url);
          Uri finalUri = uri.replace(queryParameters: request.params);
          response = await client.get(finalUri, headers: headers);
          break;

        case Method.post:
          response = await client.post(
            Uri.parse(request.url),
            headers: headers,
            body: jsonEncode(request.body),
          );
          break;

        case Method.put:
          response = await client.put(
            Uri.parse(request.url),
            headers: headers,
            body: jsonEncode(request.body),
          );
          break;

        case Method.delete:
          response = await client.delete(
            Uri.parse(request.url),
            headers: headers,
            body: jsonEncode(request.body),
          );
          break;

        default:
          response = await client.post(
            Uri.parse(request.url),
            headers: headers,
            body: jsonEncode(request.body),
          );
      }

      devPrint("📥 Retry response for ${request.url}: ${response.statusCode}");

      // Parse response
      ApiResponse? responseMap;
      try {
        if (Encryption.instance.status) {
          String decryptedResponse = await Encryption.instance.aesDecrypt(
            data: response.body,
            aesTreasure: aesTreasure,
          );
          responseMap = json.decode(decryptedResponse);
        } else {
          responseMap = json.decode(response.body);
        }

        devPrint("📥 Retry response data: ${json.encode(responseMap)}");
      } catch (e) {
        devPrint("❌ Retry response parse error: $e");
      }

      // Complete the original completer
      if (!completer.isCompleted) {
        if (response.statusCode == 200) {
          completer.complete(responseMap);
          devPrint(
            "✅ Retry successful and completer completed for: ${request.url}",
          );
        } else if (response.statusCode == 401) {
          devPrint("❌ Still 401 after refresh for: ${request.url}");
          completer.complete(responseMap);
          await _logout();
        } else {
          devPrint(
            "⚠️ Retry returned ${response.statusCode} for: ${request.url}",
          );
          completer.complete(responseMap);
        }
      } else {
        devPrint("⚠️ Completer already completed for: ${request.url}");
      }

      client.close();
    } catch (e, stackTrace) {
      devPrint("❌ Retry failed for ${request.url}: $e");
      devPrint("Stack: $stackTrace");
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }

  /// Refresh token directly
  Future<bool> _refreshTokenDirect() async {
    try {
      final userController = getIt<UserController>();
      await userController.getUserData();
      final refreshToken = userController.userData?.value.refreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        devPrint("❌ No refresh token available");
        return false;
      }

      devPrint("🔄 Calling refresh token API...");
      devPrint("🔑 Using refresh token: ${refreshToken.substring(0, 20)}...");

      final url = BuildVariantService.instance.baseUrl + URLS.refreshToken;

      final response = await http.post(
        Uri.parse(url),
        headers: await CommonValues.commonHeaders(),
        body: json.encode({'refresh_token': refreshToken}),
      );

      devPrint("🔍 Refresh token response: ${response.statusCode}");
      devPrint("📥 Response body: ${response.body}");

      if (response.statusCode != 200) {
        devPrint("❌ Refresh failed: ${response.statusCode}");
        return false;
      }

      final responseData = json.decode(response.body);
      final newAccessToken = responseData['data']?['access_token'];
      final newRefreshToken = responseData['data']?['refresh_token'];
      final expiresIn = responseData['data']?['expires_in'];

      if (newAccessToken == null || newAccessToken.isEmpty) {
        devPrint("❌ No access token in response");
        return false;
      }

      devPrint("🔑 New access token: ${newAccessToken.substring(0, 20)}...");

      // Update user data
      final currentUserData = userController.userData?.value;
      final updatedUserData = currentUserData?.copyWith(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
        expiresIn: expiresIn,
      );
      await userController.saveUserToken(newAccessToken);
      await userController.saveUserData(updatedUserData);

      // ✅ Verify token was saved
      final verifyToken = userController.userData?.value?.accessToken;
      devPrint(
        "✅ Token saved. Verification: ${verifyToken?.substring(0, 20)}...",
      );

      return true;
    } catch (e, stackTrace) {
      devPrint('❌ Refresh token error: $e');
      devPrint('Stack: $stackTrace');
      return false;
    }
  }

  Future<void> _logout() async {
    try {
      devPrint("🚪 Logging out...");

      // Clear queue
      DefaultApiEngine.instance.clearQueue();

      // Clear tokens
      await getIt<UserController>().saveUserData(null);
      await getIt<UserController>().saveUserToken("");

      // Navigate to login
      // Get.offAll(() => const LoginScreen());
      // CommonMethods.cupertinoOffAll(const LoginScreen());
    } catch (e) {
      devPrint("❌ Logout error: $e");
    }
  }

  Future<void> _onError(
    ApiRequest request, [
    Map<String, dynamic>? responseMap,
  ]) async {
    String? message;

    if (responseMap != null) {
      message = responseMap["message"];
    }

    if (request.errorPresentationType == ErrorPresentationType.dialog) {
      await Dialogs.def(
        message: message ?? "Something went wrong",
        hideSecondIcon: true,
      );
    }
  }
}

/// Helper class to store pending requests
class _PendingRequest {
  final ApiRequest request;
  final Completer<ApiResponse> completer;
  final AesTreasure aesTreasure;

  _PendingRequest({
    required this.request,
    required this.completer,
    required this.aesTreasure,
  });
}

// class ApiService {
//   static ApiService? _instance;
//
//   ApiService._internal();
//
//   static ApiService get instance {
//     _instance ??= ApiService._internal();
//     return _instance!;
//   }
//
//   /// This method is the starting point of the API call.
//   Future<ApiResponse> call({required ApiRequest request}) async {
//     if (NetworkService.instance.apiModel != null) {
//       ApiResponse response;
//       request.url =
//           ((request.customBaseUrl?.isNotEmpty ?? false)
//               ? (request.customBaseUrl ?? "")
//               : BuildVariantService.instance.baseUrl) +
//           request.url;
//       switch (NetworkService.instance.apiModel?.apiType) {
//         case ApiType.def:
//           response = await DefaultApiEngine.instance.call(request: request);
//           break;
//         case ApiType.sequential:
//           response = await SequentialApiEngine.instance.call(request: request);
//           break;
//         default:
//           response = await DefaultApiEngine.instance.call(request: request);
//       }
//
//       return response;
//     }
//
//     return null;
//   }
//
//   /// This method is used to check whether the API response is correct or not based on the statusCode and the response body.
//   Future<void> evaluateResponse({
//     required http.Response response,
//     required ApiRequest request,
//     required AesTreasure aesTreasure,
//     required Completer<ApiResponse> completer,
//   }) async {
//     ApiResponse responseMap;
//
//     devPrint("${request.url} | Status Code | ${response.statusCode}");
//
//     try {
//       if (Encryption.instance.status) {
//         String decryptedResponse = await Encryption.instance.aesDecrypt(
//           data: response.body,
//           aesTreasure: aesTreasure,
//         );
//         devPrint("${request.url} | Encrypted Response | ${response.body}");
//         devPrint("${request.url} | Decrypted Response | $decryptedResponse");
//         responseMap = json.decode(decryptedResponse);
//       } else {
//         devPrint("${request.url} | Response | ${response.body}");
//         responseMap = json.decode((response.body));
//       }
//
//       // 🔥 ADD THIS HERE
//       await UpdateController().handleVersionFromApi(responseMap);
//     } catch (e) {
//       devPrint("Response json.decode error: $e");
//     }
//
//     if (request.scripts?.preCheckResponse != null && responseMap != null) {
//       await request.scripts!.preCheckResponse!(request, responseMap, completer);
//     }
//
//     switch (response.statusCode) {
//       case 200:
//         break;
//
//       case 500:
//         devPrint(
//           'API call failed because of getting ${response.statusCode} status code in Response.',
//         );
//         await _onError(request, responseMap);
//         break;
//
//       case 401:
//         await _handle401(
//           request: request,
//           responseMap: responseMap,
//           completer: completer,
//         );
//         return;
//
//       // case 401:
//       //   devPrint('API call failed because user is unauthorised');
//       //   // await _onError(request, responseMap);
//       //   Dialogs.def(
//       //     message: responseMap?["message"] ?? "Something went wrong",
//       //     barrierDismissible: false,
//       //     hideSecondIcon: true,
//       //     onTap: () async {
//       //       await getIt<UserController>().saveUserData(null);
//       //       await getIt<UserController>().saveUserToken("");
//       //       Get.offAll(() => const LoginScreen());
//       //     },
//       //   );
//       //   break;
//       case 400:
//         Dialogs.def(
//           message: responseMap?["message"] ?? "Something went wrong",
//           barrierDismissible: false,
//           hideSecondIcon: true,
//         );
//       default:
//         devPrint(
//           'API call failed because of getting ${response.statusCode} status code in Response.',
//         );
//         await _onError(request, responseMap);
//         break;
//     }
//
//     if (!completer.isCompleted) {
//       completer.complete(responseMap);
//     }
//   }
//
//   Future<void> _onError(
//     ApiRequest request, [
//     Map<String, dynamic>? responseMap,
//   ]) async {
//     String? message;
//
//     if (responseMap != null) {
//       message = responseMap["message"];
//     }
//
//     if (request.errorPresentationType == ErrorPresentationType.dialog) {
//       await Dialogs.def(
//         message: message ?? "Something went wrong",
//         hideSecondIcon: true,
//       );
//     }
//   }
//
//   bool _isRefreshing = false;
//   Completer<bool>? _refreshCompleter;
//
//   /// HANDLE 401 WITH RETRY PROTECTION
//   Future<void> _handle401({
//     required ApiRequest request,
//     required Map<String, dynamic>? responseMap,
//     required Completer<ApiResponse> completer,
//   }) async {
//     devPrint("401 received. Checking retry flag.");
//
//     if (request.hasRetried) {
//       devPrint("Already retried once. Logging out.");
//       await _logout();
//       return;
//     }
//
//     final refreshed = await _refreshToken();
//
//     if (!refreshed) {
//       devPrint("Refresh failed. Logging out.");
//       await _logout();
//       return;
//     }
//
//     devPrint("Token refreshed. Retrying request.");
//
//     final retryRequest = request.copyWith(hasRetried: true);
//
//     final retryResponse = await call(request: retryRequest);
//
//     if (!completer.isCompleted) {
//       completer.complete(retryResponse);
//     }
//   }
//
//   /// REFRESH TOKEN WITH MUTEX LOCK
//   Future<bool> _refreshToken() async {
//     if (_isRefreshing) {
//       return _refreshCompleter!.future;
//     }
//
//     _isRefreshing = true;
//     _refreshCompleter = Completer<bool>();
//
//     try {
//       final success = await AuthController().refreshToken();
//
//       _refreshCompleter!.complete(success);
//       return success;
//     } catch (e) {
//       _refreshCompleter!.complete(false);
//       return false;
//     } finally {
//       _isRefreshing = false;
//     }
//   }
//
//   Future<void> _logout() async {
//     await UserController().saveUserData(null);
//     await UserController().saveUserToken("");
//     Get.offAll(() => const LoginScreen());
//   }
// }
