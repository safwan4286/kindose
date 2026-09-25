import 'package:get/get.dart';

import '../models/user_data_model.dart';
import '../services/local_storage/local_storage.dart';
import '../services/logs/logs.dart';

class UserController extends GetxController {
  static UserController? _instance;

  factory UserController() {
    _instance ??= UserController._internal();
    return _instance!;
  }

  UserController._internal();

  // ---------------- USER DATA ----------------

  Future<void> saveUserData(UserData? userData) async {
    try {
      await LocalStorage().writeData(
        boxName: HiveBox.user,
        key: HiveKeys.userData,
        value: userData,
      );
    } catch (e) {
      devPrint("error :- saveUserData ${e.toString()}");
    }
  }

  Rx<UserData>? userData;

  Future<UserData?> getUserData() async {
    try {
      final Map<String, dynamic>? userDataJson = await LocalStorage().readData(
        boxName: HiveBox.user,
        key: HiveKeys.userData,
      );

      if (userDataJson != null) {
        userData = UserData.fromJson(userDataJson).obs;
      }
    } catch (e) {
      devPrint("error :- getUserData ${e.toString()}");
    }
    return userData?.value;
  }

  // ---------------- TOKEN ----------------

  Future<void> saveUserToken(String token) async {
    try {
      await LocalStorage().writeData(
        boxName: HiveBox.user,
        key: HiveKeys.userToken,
        value: token,
      );
    } catch (e) {
      devPrint("error :- saveUserToken ${e.toString()}");
    }
  }

  Future<String> getUserToken() async {
    try {
      return await LocalStorage().readData(
            boxName: HiveBox.user,
            key: HiveKeys.userToken,
          ) ??
          "";
    } catch (e) {
      devPrint("error :- getUserToken ${e.toString()}");
      return "";
    }
  }

  // ---------------- BUSINESS FLAG ----------------

  Future<void> saveHasBusinessDetails(bool value) async {
    try {
      await LocalStorage().writeData(
        boxName: HiveBox.user,
        key: HiveKeys.hasBusinessDetails,
        value: value,
      );
    } catch (e) {
      devPrint("error :- saveHasBusinessDetails ${e.toString()}");
    }
  }

  Future<bool> hasBusinessDetails() async {
    try {
      return await LocalStorage().readData(
            boxName: HiveBox.user,
            key: HiveKeys.hasBusinessDetails,
          ) ??
          false;
    } catch (e) {
      devPrint("error :- hasBusinessDetails ${e.toString()}");
      return false;
    }
  }

  Future<void> deleteUserLocally() async {
    try {
      final localStorage = LocalStorage();

      // Delete specific keys
      await localStorage.deleteData(
        boxName: HiveBox.user,
        key: HiveKeys.userData,
      );

      await localStorage.deleteData(
        boxName: HiveBox.user,
        key: HiveKeys.userToken,
      );

      // Reset reactive state
      userData = null;
    } catch (e) {
      devPrint("error :- deleteUser ${e.toString()}");
    }
  }
}
