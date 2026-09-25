

import '../../../progress_indicator/loader.dart';
import '../models/api_progress_indicator.dart';

const Map<String, dynamic> emptyMap = {};

ApiProgressIndicator defaultProgressIndicator = ApiProgressIndicator(
  showLoader: () {
    Loader.instance.show();
  },
  hideLoader: () {
    Loader.instance.hide();
  },
);
