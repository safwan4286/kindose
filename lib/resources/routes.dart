import 'package:get/get.dart';

import '../features/check_in/check_in_binding.dart';
import '../features/check_in/check_in_screen.dart';
import '../features/dose_done/dose_done_binding.dart';
import '../features/dose_done/dose_done_screen.dart';
import '../features/home/home_binding.dart';
import '../features/home/home_screen.dart';
import '../features/intake/intake_binding.dart';
import '../features/intake/intake_screen.dart';
import '../features/log_dose/log_dose_binding.dart';
import '../features/log_dose/log_dose_screen.dart';
import '../features/offer/offer_binding.dart';
import '../features/offer/offer_screen.dart';
import '../features/onboarding/onboarding_binding.dart';
import '../features/onboarding/onboarding_screen.dart';
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

  /// Pass a DoseDoneArgs.
  static const String doseDone = '/dose-done';

  /// Pass 'protein' or 'water' as the argument.
  static const String addIntake = '/add-intake';
  static const String checkIn = '/check-in';
  static const String reportPreview = '/report-preview';
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
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: Routes.logDose,
      page: () => const LogDoseScreen(),
      binding: LogDoseBinding(),
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
    ),
    GetPage<dynamic>(
      name: Routes.checkIn,
      page: () => const CheckInScreen(),
      binding: CheckInBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.reportPreview,
      page: () => const ReportPreviewScreen(),
    ),
  ];
}
