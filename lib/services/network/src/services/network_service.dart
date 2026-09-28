import '../models/api_model.dart';
import 'build_variant/build_variants_service.dart';
import 'encryption/encryption.dart';

class NetworkService {
  static NetworkService? _instance;

  NetworkService._internal();

  static NetworkService get instance {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  ApiModel? apiModel;

  void start(ApiModel api) {
    apiModel = api;
    Encryption.instance.status = api.encryptionEnabled;

    BuildVariantService.instance.setEnvironment(
      environment: api.buildVariants.defaultEnvironment,
    );
  }

  void end() {
    apiModel = null;
  }
}
