import 'package:flutter/material.dart';

import '../get_it/get_it_setup.dart';
import '../local_storage/local_storage.dart';

class Localization {
  static Localization? _instance;

  Localization._internal();

  static Localization get instance {
    _instance ??= Localization._internal();
    return _instance!;
  }

  Locale? currentLanguage;

  Future<Locale> setLocale(String languageCode) async {
    await getIt<LocalStorage>().writeData<String>(
      boxName: HiveBox.user,
      key: HiveKeys.preferredLanguage,
      value: languageCode,
    );
    return _locale(languageCode);
  }

  Future<Locale> getLocale() async {
    String? preferredLanguage = await getIt<LocalStorage>().readData(
      boxName: HiveBox.user,
      key: HiveKeys.preferredLanguage,
    );
    return _locale(preferredLanguage ?? "en");
  }

  Locale _locale(String languageCode) {
    if (languageCode.isNotEmpty) {
      return Locale(languageCode, '');
    } else {
      return const Locale('en', '');
    }
  }

  void changeLanguage(BuildContext context, String selectedLanguageCode) async {
    await setLocale(selectedLanguageCode);
    if (context.mounted) {
      // MyApp.setLocale(context, locale);
    }
  }
}
