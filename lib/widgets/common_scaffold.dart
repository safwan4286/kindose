import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/base_controller.dart';
import '../services/get_it/get_it_setup.dart';

class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.visibleBackground = false,
    this.bottomNavigationBar,
    this.systemUiOverlayStyle,
    this.floatingActionButton,
    this.safeAreaBottom = true,
    this.safeAreaTop = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool visibleBackground;
  final bool safeAreaBottom;
  final bool safeAreaTop;
  final Widget? bottomNavigationBar;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          // 1. Blurred content
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: getIt<BaseController>().isBlurApplied.value ? 5 : 0,
              sigmaY: getIt<BaseController>().isBlurApplied.value ? 5 : 0,
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: resizeToAvoidBottomInset,
              backgroundColor: backgroundColor,
              appBar: appBar,
              bottomNavigationBar: bottomNavigationBar,
              body: SafeArea(
                top: safeAreaTop,
                bottom: safeAreaBottom,
                child: visibleBackground
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            height: Get.height * 0.23,
                            decoration: const BoxDecoration(),
                          ),
                          body,
                        ],
                      )
                    : body,
              ),
              floatingActionButton: floatingActionButton,
            ),
          ),

          // 2. Color overlay (only visible when blur is on)
          if (getIt<BaseController>().isBlurApplied.value)
            Container(
              color: Colors.black.withOpacity(0.25),
              // Change to any color you want
              // e.g. AppColors.primary.withOpacity(0.15)
            ),
        ],
      ),
    );
  }
}
