// ignore_for_file: non_constant_identifier_names

abstract class Params {
  static const String accessToken = "access_token";
  static const String category = "category";
  static const String currencyCode = "currency_code";
}

abstract class Body {
  static const String email = "email";
  static const String password = "password";
  static const String deviceType = "Device-Type";
  static const String platform = "Platform";
  static const String deviceToken = "device_token";
  static const String deviceId = "Device-ID";
  static const String fcmToken = "fcm-token";
  static const String adminId = "admin_id";
  static const String orderId = "orderId";
  static const String userId = "userId";
  static const String customerID = "customerID";
  static const String appVersion = "app_version";
  static const String refreshToken = "refresh_token";
  static const String currentBusinessId = "current-business-id";
}

abstract class Headers {
  static const String accessToken = "access_token";
  static String AUTHORIZATION = "Authorization";
  static String USER_IP_ADDRESS = "user_ipaddress";
}

abstract class CommonValues {
  static String DATE_FORMAT = "yyyy-MM-dd";
  static String DD_MMM_YYYY_FORMAT = "dd MMM yyyy";
  static String COUNTRY_MOBILE_CODE = "+91";
  static String COUNTRY_MOBILE_CODE_WITHOUT_SYMBOL = "91";
  // static String INDIAN_RUPEE_SYMBOL = "₹";
  // static String US_CURRENCY_SYMBOL = "\$";
}

abstract class InstanceName {
  static String remote = "REMOTE";
  static String local = "LOCAL";
}

abstract class APIConstants {
  static int pageSize = 10;
  static int ascending = 1;
  static int descending = -1;
  static int timeoutDuration = 30;
}

abstract class APIKeys {
  static String GOOGLE_API_KEY = "";
}

abstract class PaymentConstants {
  static String androidRevenueCatApiKey = "goog_xnDNRHfKNVZxlsLSfcvGIGdvcsP";
  static String iosRevenueCatApiKey = "appl_wKeZBcLcumIEwkNZiKsEmGQibym";
  static String entitlementID = 'lifetime_access';
  static String proAccess = 'pro_access';
}

abstract class AppConstant {
  static String appstoreId = "";
  static String appName = "Jawlyn";
}

const double defaultBlurValue = 6;

enum LoginType { apple, google }
