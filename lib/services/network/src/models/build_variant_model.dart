
import '../services/build_variant/build_variants_service.dart';

class BuildVariants {
  final String productionUrl;
  final String? stagingUrl;
  final String? localUrl;

  final Environment defaultEnvironment;
  final String? currentUrl;

  BuildVariants({
    required this.productionUrl,
    this.stagingUrl,
    this.localUrl,
    required this.defaultEnvironment,
    this.currentUrl,
  }) : assert((defaultEnvironment == Environment.local &&
                (localUrl?.isNotEmpty ?? false)) ||
            (defaultEnvironment == Environment.production &&
                productionUrl.isNotEmpty) ||
            (defaultEnvironment == Environment.staging &&
                (stagingUrl?.isNotEmpty ?? false)));
}
