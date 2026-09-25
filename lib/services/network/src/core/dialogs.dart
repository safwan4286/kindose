import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../../controllers/base_controller.dart';
import '../../../../resources/colors.dart';
import '../../../../resources/common_methods.dart';
import '../../../../resources/images.dart';
import '../../../../widgets/common_dialog.dart';
import '../../../get_it/get_it_setup.dart';
import '../../../localization/language/languages.dart';
import '../../../logs/logs.dart';
import '../../../progress_indicator/loader.dart';
import '../services/network_service.dart';

class Dialogs {
  static def({
    required String message,
    Function? onTap,
    Function? onTapSecond,
    bool barrierDismissible = true,
    String? buttonText,
    String? buttonTextSecond,
    bool hideSecondIcon = false,
    String? image,
    String? title,
    Color? firstButtonColor,
    Color? barrierColor,
    bool showImage = false,
  }) async {
    try {
      if (!(Get.isDialogOpen ?? false)) {
        Loader.instance.hide();
        NetworkService.instance.apiModel?.progressIndicator?.hideLoader();
        getIt<BaseController>().isBlurApplied.value = true;
        await Get.dialog(
          CommonDialog(
                title: title ?? "",
                message: message,
                hideSecondIcon: hideSecondIcon,
                buttonTextSecond: buttonTextSecond,
                onTapSecondButton: onTapSecond,
                firstButtonColor: firstButtonColor,
                showImage: showImage,
                onTap: () {
                  if (onTap != null) {
                    onTap();
                  } else {
                    // Get.back();
                    CommonMethods.goBack();
                  }
                },
                image: image ?? Img3d.bell,
                buttonText: buttonText ?? Languages.of(Get.context!).okayLabel,
              )
              .animate()
              .fade(duration: 400.ms, curve: Curves.fastOutSlowIn)
              .scale(duration: 400.ms, curve: Curves.fastOutSlowIn),
          barrierColor:
              barrierColor ?? AppColors.common252B3D.withOpacity(0.69),
          barrierDismissible: barrierDismissible,
        );
        getIt<BaseController>().isBlurApplied.value = false;
      }
    } catch (e) {
      getIt<BaseController>().isBlurApplied.value = false;
      devPrint("Dialogs.def error $e");
    } finally {
      getIt<BaseController>().isBlurApplied.value = false;
    }
  }
}
