import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../resources/colors.dart';
import '../resources/fonts.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import 'bounce.dart';
import 'common_text.dart';



class CommonButton extends StatefulWidget {
  final double? height;
  final double? width;
  final Color? borderColor;
  final String label;
  final bool? isEnabled;
  final TextStyle? labelTextStyle;
  final Function onTap;
  final Color? enabledColor;
  final Color? disabledColor;
  final double? borderRadius;
  final bool centerText;
  final String? leftIcon;
  final String? rightIcon;
  final double? spaceFromLeft;
  final double? spaceFromRight;
  final Color? iconColor;
  final bool isButtonAnimationEnable;
  final double? iconSize;
  final double? bottomSpace;
  final List<BoxShadow>? shadow;
  final Widget? child;

  const CommonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.labelTextStyle,
    this.height,
    this.width,
    this.borderColor,
    this.isEnabled,
    this.disabledColor,
    this.enabledColor,
    this.centerText = false,
    this.borderRadius,
    this.leftIcon,
    this.rightIcon,
    this.spaceFromLeft,
    this.spaceFromRight,
    this.iconColor,
    this.iconSize,
    this.bottomSpace,
    this.isButtonAnimationEnable = false,
    this.shadow,
    this.child,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> {
  bool isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpace ?? 15.0.sp),
      child:
          BounceClick(
                onTap: () {
                  if (widget.isEnabled ?? false) {
                    Haptics.instance.heavyImpact();
                    widget.onTap();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: widget.height ?? (Get.height * 0.067),
                  width: widget.width ?? (Get.height * 0.9),
                  decoration: BoxDecoration(
                    color: widget.isButtonAnimationEnable
                        ? widget.enabledColor ?? AppColors.primary
                        : (widget.isEnabled ?? false)
                        ? widget.enabledColor ?? AppColors.primary
                        : widget.disabledColor ?? AppColors.lightGreyTextColor,
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius ?? 20.0.sp,
                    ),
                    boxShadow: widget.shadow,
                    border: Border.all(
                      color: widget.borderColor ?? Colors.transparent,
                    ),
                  ),
                  child:
                      widget.child ??
                      (widget.centerText
                          ? Center(
                              child: CommonText(
                                widget.label,
                                style:
                                    widget.labelTextStyle ??
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.white,
                                      fontSize: 15.sp,
                                      fontFamily: Fonts.sfProBoldDisplay,
                                    ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.leftIcon != null)
                                  Image.asset(
                                    widget.leftIcon!,
                                    color: widget.iconColor ?? AppColors.white,
                                    height: widget.iconSize ?? 20.sp,
                                  ),
                                if (widget.leftIcon != null)
                                  SizedBox(
                                    width: widget.spaceFromLeft ?? 10.sp,
                                  ),
                                CommonText(
                                  widget.label,
                                  style:
                                      widget.labelTextStyle ??
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.white,
                                        fontSize: 15.sp,
                                        fontFamily: Fonts.sfProBoldDisplay,
                                      ),
                                ),
                                if (widget.rightIcon != null)
                                  SizedBox(
                                    width: widget.spaceFromRight ?? 10.sp,
                                  ),
                                if (widget.rightIcon != null)
                                  Image.asset(
                                    widget.rightIcon!,
                                    color: widget.iconColor ?? AppColors.white,
                                    height: widget.iconSize ?? 20.sp,
                                  ),
                              ],
                            )),
                ),
              )
              .animate(
                target:
                    widget.isButtonAnimationEnable &&
                        (widget.isEnabled ?? false)
                    ? 1
                    : 0,
              )
              .then()
              .moveY(
                duration: (widget.isEnabled ?? false) ? 400.ms : 1000.ms,
                begin: widget.isButtonAnimationEnable
                    ? (widget.isEnabled ?? false)
                          ? (widget.height ?? Get.height * 0.067) +
                                (widget.bottomSpace ?? 20)
                          : Get.height * 0.5
                    : 0,
                curve: Curves.easeInOutBack,
              ),
    );
  }
}
