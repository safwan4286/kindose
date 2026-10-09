import 'package:get/get.dart';


import '../features/account/save_data_screen.dart';
import '../features/update/update_screen.dart';
import '../features/check_in/check_in_binding.dart';
import '../features/check_in/check_in_screen.dart';
import '../features/day/day_binding.dart';
import '../features/day/day_screen.dart';
import '../features/dose_done/dose_done_binding.dart';
import '../features/dose_done/dose_done_screen.dart';
import '../features/home/home_binding.dart';
import '../features/home/home_screen.dart';
import '../features/home/weight_sheet.dart';
import '../features/guide/guide_binding.dart';
import '../features/guide/guide_screen.dart';
import '../features/intake/intake_binding.dart';
import '../features/intake/intake_screen.dart';
import '../features/log_dose/log_dose_binding.dart';
import '../features/log_dose/log_dose_screen.dart';
import '../features/notifications/notifications_controller.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/offer/offer_binding.dart';
import '../features/offer/offer_screen.dart';
import '../features/onboarding/onboarding_binding.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pens/pens_binding.dart';
import '../features/pens/pens_screen.dart';
import '../features/plus/plus_binding.dart';
import '../features/plus/plus_screen.dart';
import '../features/report/report_preview_screen.dart';
import '../features/splash/splash_binding.dart';
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcome_binding.dart';
import '../features/welcome/welcome_screen.dart';

class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String editPlan = '/edit-plan';
  static const String plus = '/plus';

  /// Discount offer after closing the paywall. Pass an OfferArgs.
  static const String offer = '/offer';
  static const String home = '/home';
  static const String logDose = '/log-dose';

  /// Weigh-in (was a bottom sheet).
  static const String logWeight = '/log-weight';

  /// Pass a DoseDoneArgs.
  static const String doseDone = '/dose-done';

  /// Pass 'protein' or 'water' as the argument.
  static const String addIntake = '/add-intake';
  static const String checkIn = '/check-in';

  /// One day at a glance. Pass a DateTime (defaults to today).
  static const String day = '/day';
  static const String reportPreview = '/report-preview';

  /// Pens & cost (Plus).
  static const String pens = '/pens';

  /// Injection guide. Pass a GuideArgs when opened from Log dose.
  static const String guide = '/guide';
  static const String saveData = '/save-data';
  static const String update = '/update';

  /// Me → Notifications: a switch per reminder, quiet hours.
  static const String notifications = '/notifications';
}

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage<dynamic>(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.noTransition,
    ),
    GetPage<dynamic>(
      name: Routes.welcome,
      page: () => const WelcomeScreen(),
      binding: WelcomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage<dynamic>(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.editPlan,
      page: () => const OnboardingScreen(),
      binding: EditPlanBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.plus,
      page: () => const PlusScreen(),
      binding: PlusBinding(),
      transition: Transition.downToUp,
    ),
    GetPage<dynamic>(
      name: Routes.offer,
      page: () => const OfferScreen(),
      binding: OfferBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.update,
      page: () => const UpdateScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.saveData,
      page: () => const SaveDataScreen(),
      binding: SaveDataBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.logDose,
      page: () => const LogDoseScreen(),
      binding: LogDoseBinding(),
      // Opens freely; saving asks for Plus (AccessService.ensure).
    ),
    GetPage<dynamic>(
      name: Routes.doseDone,
      page: () => const DoseDoneScreen(),
      binding: DoseDoneBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.addIntake,
      page: () => const IntakeScreen(),
      binding: IntakeBinding(),
      // Opens freely; saving asks for Plus (AccessService.ensure).
    ),
    GetPage<dynamic>(
      name: Routes.day,
      page: () => const DayScreen(),
      binding: DayBinding(),
      // Open for browsing; Plus actions inside ask (soft paywall).
    ),
    GetPage<dynamic>(
      name: Routes.logWeight,
      page: () => const WeightScreen(),
    ),
    GetPage<dynamic>(
      name: Routes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.pens,
      page: () => const PensScreen(),
      binding: PensBinding(),
      // Open for browsing; Plus actions inside ask (soft paywall).
    ),
    GetPage<dynamic>(
      name: Routes.guide,
      page: () => const GuideScreen(),
      binding: GuideBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.checkIn,
      page: () => const CheckInScreen(),
      binding: CheckInBinding(),
      // Opens freely; saving asks for Plus (AccessService.ensure).
    ),
    GetPage<dynamic>(
      name: Routes.reportPreview,
      page: () => const ReportPreviewScreen(),
      // Preview is free to look at; Share asks for Plus.
    ),
  ];
}
