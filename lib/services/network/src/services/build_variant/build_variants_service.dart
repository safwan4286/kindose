import '../network_service.dart';

enum Environment { staging, production, local }

class BuildVariantService {
  static BuildVariantService? _instance;

  BuildVariantService._internal();

  static BuildVariantService get instance {
    _instance ??= BuildVariantService._internal();
    return _instance!;
  }

  Environment currentEnvironment = Environment.local;

  void setEnvironment({required Environment environment}) {
    currentEnvironment = environment;
  }

  String get baseUrl {
    switch (currentEnvironment) {
      case Environment.staging:
        return NetworkService.instance.apiModel?.buildVariants.stagingUrl ?? "";
      case Environment.local:
        return NetworkService.instance.apiModel?.buildVariants.localUrl ?? "";
      case Environment.production:
        return NetworkService.instance.apiModel?.buildVariants.productionUrl ??
            "";
    }
  }
}
