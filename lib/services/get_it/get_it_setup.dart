import 'package:get_it/get_it.dart';
import '../../controllers/base_controller.dart';
import '../local_storage/local_storage.dart';

final getIt = GetIt.instance;

void singletonsSetup() {
  getIt.registerSingleton<BaseController>(BaseController());
  getIt.registerSingleton<LocalStorage>(LocalStorage());
}
