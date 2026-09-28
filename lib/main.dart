import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:kindose/resources/functions.dart';
import 'package:kindose/services/app_info.dart';
import 'package:kindose/services/get_it/get_it_setup.dart';
import 'package:kindose/services/local_storage/local_storage.dart';
import 'package:kindose/services/logs/logs.dart';
import 'package:kindose/services/responsiveness/device_manager.dart';
import 'package:kindose/services/theme/theme.dart';

import 'resources/routes.dart';
import 'services/notifications/reminder_service.dart';
import 'services/offers/offer_service.dart';
import 'services/tracker_service.dart';
import 'services/theme/system_ui.dart';

/// Widest the app gets. Tablets show a centred phone-width column.
const double kMaxAppWidth = 520;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerAssetLicences();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await KSystemUi.enableEdgeToEdge();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      // Send errors to a logging service or print errors
      devPrint(details.toString()); // Only temporary for debugging
    }
  };

  /// notification setup
  // try {
  //   /// Notification setup
  //   await Firebase.initializeApp();
  //
  //   if (kDebugMode) {
  //     await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  //   }
  //
  //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //   devPrint('Firebase initialized and background handler set.');
  // } catch (e, stackTrace) {
  //   devPrint('Error initializing Firebase or setting background handler: $e');
  // }
  // if (!kIsWeb) {
  //   await setupFlutterNotifications();
  //   initializeNotifications();
  // }

  singletonsSetup();

  // local storage initilization
  await getIt<LocalStorage>().initHive();

  /// firebase token logic

  // await DeviceInfo().get();

  await AppInfo().get();

  final tracker = await Get.putAsync<TrackerService>(
    () => TrackerService().init(),
    permanent: true,
  );
  // Plans dose reminders from the schedule and re-plans on every change.
  Get.put<ReminderService>(ReminderService(), permanent: true);
  // Discount offer rules (backend-driven later via Remote Config).
  Get.put<OfferService>(OfferService(), permanent: true);

  runApp(
    KindoseApp(initialRoute: Routes.splash, themeMode: tracker.themeMode.value),
  );
}

/// Fonts and 3D illustrations are bundled, so their licences are shown on
/// the "View all licences" page next to the package licences.
void _registerAssetLicences() {
  LicenseRegistry.addLicense(() async* {
    const files = {
      'Figtree': 'assets/licenses/figtree_OFL.txt',
      'Bricolage Grotesque': 'assets/licenses/bricolage_OFL.txt',
      'Fluent Emoji (Microsoft)': 'assets/licenses/fluent_emoji_MIT.txt',
    };
    for (final e in files.entries) {
      final text = await rootBundle.loadString(e.value);
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}

class KindoseApp extends StatelessWidget {
  const KindoseApp({
    super.key,
    required this.initialRoute,
    required this.themeMode,
  });

  final String initialRoute;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    DeviceManager.instance.init(context);
    return GestureDetector(
      onTap: () => Functions.dismissKeyboard(),
      child: GetMaterialApp(
        title: 'Kindose',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        initialRoute: initialRoute,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final mq = MediaQuery.of(context);
          // Tablets and wide windows keep the phone layout in a centred
          // column instead of stretching every card.
          final width = math.min(mq.size.width, kMaxAppWidth);
          final data = mq.copyWith(
            size: Size(width, mq.size.height),
            // Allow large text but cap it so fixed-size tiles stay usable.
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.35),
          );
          DeviceManager.instance.initWith(data);
          Widget app = MediaQuery(data: data, child: child ?? const SizedBox.shrink());
          if (width < mq.size.width) {
            app = ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(child: SizedBox(width: width, child: ClipRect(child: app))),
            );
          }
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: KSystemUi.style(darkBackground: dark),
            child: app,
          );
        },
      ),
    );
  }
}
