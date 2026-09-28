
import '../../resources/common_methods.dart';
import '../../resources/functions.dart';
import '../../widgets/global_loader.dart';

class Loader {
  static Loader? _instance;

  Loader._internal();

  static Loader get instance {
    _instance ??= Loader._internal();
    return _instance!;
  }

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void show() async {
    if (!_isLoading) {
      Functions.openDialog(
        canCloseDialog: false,
        body: const GlobalLoaderWidget(),
      );
      _isLoading = true;
    }
  }

  void hide() {
    if (_isLoading) {
      _isLoading = false;
      // Get.back();
      CommonMethods.goBack();
    }
  }
}
