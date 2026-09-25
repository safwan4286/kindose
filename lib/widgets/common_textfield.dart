import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';

class CommonTextField extends StatefulWidget {
  final String? hintText;
  final String? errorText;
  final TextStyle? hintTextStyle;
  final TextEditingController? controller;
  final TextStyle? textStyle;
  final double? borderRadius;
  final double? textFieldHeight;
  final Function? onChanged;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool? autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Function? onSubmit;
  final TextInputType? textInputType;
  final Widget? rightIcon;
  final BoxConstraints? rightIconConstraints;
  final Color? rightIconColor;
  final Widget? leftIcon;
  final BoxConstraints? leftIconConstraints;
  final Color? leftIconColor;
  final bool showCursor;
  final bool isOnlyBottomBorder;
  final List<TextInputFormatter>? textInputFormatters;
  final Color? fillColor;
  final Color? focusUnderLineBorder;
  final Color? focusOutlineBorder;
  final Color? enabledUnderlineBorder;
  final Color? enabledOutlineBorder;
  final Color? disabledUnderlineBorder;
  final Color? disabledOutlineBorder;
  final bool filled;
  final bool isBorderEnable;
  final EdgeInsets? contentPadding;
  final bool readOnly;
  final bool obscureText;
  final bool expands;
  final bool enable;
  final bool floatingTitleEnable;
  final Color? cursorColor;
  final double? cursorHeight;
  final Brightness? keyboardAppearance;
  final String? Function(String?)? validator;
  final void Function()? onTap;

  const CommonTextField({
    Key? key,
    this.controller,
    this.rightIcon,
    this.textStyle,
    this.hintText,
    this.minLines,
    this.onSubmit,
    this.textInputAction,
    this.borderRadius,
    this.hintTextStyle,
    this.focusNode,
    this.autofocus,
    this.onChanged,
    this.textInputType,
    this.maxLines,
    this.maxLength,
    this.rightIconColor,
    this.rightIconConstraints,
    this.leftIcon,
    this.leftIconColor,
    this.leftIconConstraints,
    this.showCursor = true,
    this.textInputFormatters,
    this.isOnlyBottomBorder = false,
    this.fillColor,
    this.filled = false,
    this.focusUnderLineBorder,
    this.focusOutlineBorder,
    this.enabledUnderlineBorder,
    this.enabledOutlineBorder,
    this.disabledUnderlineBorder,
    this.disabledOutlineBorder,
    this.isBorderEnable = true,
    this.contentPadding,
    this.readOnly = false,
    this.obscureText = false,
    this.expands = false,
    this.enable = true,
    this.textFieldHeight,
    this.errorText,
    this.cursorColor,
    this.cursorHeight,
    this.keyboardAppearance,
    this.validator,
    this.floatingTitleEnable = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        if (widget.errorText?.isNotEmpty ?? false)
          ShakeEffect(
            curve: Curves.easeIn,
            duration: 300.ms,
            offset: const Offset(5, 0),
            rotation: 0,
            hz: (widget.errorText?.isNotEmpty ?? false) ? 16 : 0,
          ),
      ],
      child: TextFormField(
        onTap: widget.onTap,
        cursorColor: widget.cursorColor ?? AppColors.white,
        style:
            widget.textStyle ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontSize: 14.0.sp,
              height: 0,
            ),
        readOnly: widget.readOnly,
        focusNode: widget.focusNode,
        controller: widget.controller,
        maxLength: widget.maxLength,
        cursorErrorColor: AppColors.white,
        onChanged: (value) {
          if (widget.onChanged != null) {
            widget.onChanged!();
          }
        },
        enabled: widget.enable,
        expands: widget.expands,
        minLines: widget.minLines,
        autofocus: widget.autofocus ?? false,
        selectionHeightStyle: BoxHeightStyle.max,
        buildCounter: null,
        maxLines: widget.maxLines,
        textAlignVertical: TextAlignVertical.center,
        keyboardAppearance: widget.keyboardAppearance,
        keyboardType: widget.textInputType,
        inputFormatters: widget.textInputFormatters,
        textInputAction: widget.textInputAction ?? TextInputAction.done,
        showCursor: widget.showCursor,
        cursorHeight: widget.cursorHeight,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onFieldSubmitted: (value) {
          if (widget.onSubmit != null) {
            widget.onSubmit!();
          }
        },
        decoration: InputDecoration(
          fillColor:
              widget.fillColor ??
              ((widget.errorText?.isNotEmpty ?? false)
                  ? AppColors.darkGreyColor161616
                  : AppColors.darkGreyColor161616),
          filled: widget.filled,
          hintText: (!widget.floatingTitleEnable) ? widget.hintText : null,
          prefixIcon: widget.leftIcon,
          labelText: (widget.floatingTitleEnable) ? widget.hintText : null,

          labelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.white),
          prefixIconConstraints: widget.leftIconConstraints,
          prefixIconColor: widget.leftIconColor,
          suffixIcon: widget.rightIcon,
          suffixIconConstraints: widget.rightIconConstraints,
          suffixIconColor: widget.rightIconColor,
          counterText: "",
          // isDense: true,
          // floatingLabelAlignment: FloatingLabelAlignment.start,
          // floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.white, height: 0),
          hintStyle:
              widget.hintTextStyle ??
              Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.white, height: 0),
          contentPadding:
              widget.contentPadding ?? const EdgeInsets.only(left: 15),
          errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.darkRedColor,

            fontSize: widget.errorText?.isEmpty ?? false ? 0.0 : null,
            height: 0,
          ),
          errorText: widget.errorText,
          border: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0,
                    color: AppColors.lightThemeGreyBorderColor,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(color: AppColors.darkGreyColor),
                ),
          focusedBorder: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0,
                    color: widget.isBorderEnable
                        ? widget.focusUnderLineBorder ??
                              AppColors.lightThemeBlackColor.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(
                    color: widget.isBorderEnable
                        ? widget.focusOutlineBorder ??
                              AppColors.lightThemeBlackColor.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
          enabledBorder: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0,
                    color: widget.isBorderEnable
                        ? widget.enabledUnderlineBorder ??
                              AppColors.darkGrayColor
                        : Colors.transparent,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(
                    color: widget.isBorderEnable
                        ? widget.enabledOutlineBorder ?? AppColors.darkGrayColor
                        : Colors.transparent,
                  ),
                ),
          disabledBorder: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0,
                    color: widget.isBorderEnable
                        ? widget.disabledUnderlineBorder ??
                              AppColors.lightThemeGreyBorderColor
                        : Colors.transparent,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(
                    color: widget.isBorderEnable
                        ? widget.disabledOutlineBorder ??
                              AppColors.lightThemeGreyBorderColor
                        : Colors.transparent,
                  ),
                ),
          errorBorder: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: (widget.errorText?.isNotEmpty ?? false)
                        ? Colors.transparent
                        : Colors.transparent,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(
                    color: (widget.errorText?.isNotEmpty ?? false)
                        ? Colors.transparent
                        : Colors.transparent,
                  ),
                ),
          focusedErrorBorder: widget.isOnlyBottomBorder
              ? UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: (widget.errorText?.isNotEmpty ?? false)
                        ? Colors.transparent
                        : Colors.transparent,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 10.0,
                  ),
                  borderSide: BorderSide(
                    color: (widget.errorText?.isNotEmpty ?? false)
                        ? Colors.transparent
                        : Colors.transparent,
                  ),
                ),
        ),
      ),
    );
  }
}
