// ignore_for_file: constant_identifier_names

abstract class _Prefix {
  static const String general = "/api/v1/";
}

abstract class URLS {
  //config
  static const String config = "${_Prefix.general}config";

  static const String refreshToken = "${_Prefix.general}auth/refresh";
}
