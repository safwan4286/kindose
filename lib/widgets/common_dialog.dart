import 'package:flutter/material.dart';
import '../resources/colors.dart';
import '../resources/common_methods.dart';
import '../resources/fonts.dart';
import '../services/responsiveness/device_manager.dart';
import 'common_button.dart';
import 'common_text.dart';

class CommonDialog extends StatefulWidget {
  const CommonDialog({
    super.key,
    required this.title,
    required this.onTap,
    required this.image,
    required this.message,
    required this.buttonText,
    this.leftIcon,
    this.rightIcon,
    this.hideSecondIcon = true,
    this.showImage = false,
    this.buttonTextSecond,
    this.onTapSecondButton,
    this.firstButtonColor,
    this.checklistItems,
    this.insetPadding,
    this.imageSize,
  });

  final String? title;
  final String message;
  final String buttonText;
  final String? buttonTextSecond;
  final String image;
  final Function onTap;
  final Function? onTapSecondButton;
  final String? leftIcon;
  final String? rightIcon;
  final bool hideSecondIcon;
  final bool showImage;
  final Color? firstButtonColor;
  final List<String>? checklistItems;
  final double? insetPadding;
  final double? imageSize;

  @override
  State<CommonDialog> createState() => _CommonDialogState();
}

class _CommonDialogState extends State<CommonDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      shadowColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: widget.insetPadding ?? 25.sp,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 15.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showImage || (widget.title?.isEmpty ?? true))
              Padding(
                padding: EdgeInsets.only(bottom: 10.0.sp),
                child: Image.asset(
                  widget.image,
                  width: widget.imageSize ?? 45.0.sp,
                  height: widget.imageSize ?? 45.0.sp,
                ),
              ),
            if (widget.title?.isNotEmpty ?? false)
              Padding(
                padding: EdgeInsets.only(top: 10.0.sp, bottom: 5.0.sp),
                child: Text(
                  widget.title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: Fonts.sfProSemiboldDisplay,
                    fontSize: 19.sp,
                    color: AppColors.black242E49,
                    height: 1.2.sp,
                  ),
                ),
              ),
            if (widget.checklistItems != null &&
                widget.checklistItems!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10.sp, bottom: 20.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.checklistItems!
                      .map((item) => _ChecklistItem(item: item))
                      .toList(),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: 20.sp),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.common535862,
                    fontSize: 15.sp,
                    fontFamily: Fonts.sfProRegularDisplay,
                    height: 1.2.sp,
                  ),
                ),
              ),
            CommonButton(
              borderRadius: 20.0.sp,
              height: 43.0.sp,
              bottomSpace: 0,
              label: widget.buttonText,
              labelTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: Fonts.sfProRegularDisplay,
                fontSize: 15.0.sp,
              ),
              onTap: widget.onTap,
              enabledColor: widget.firstButtonColor ?? AppColors.primary,
              isEnabled: true,
              leftIcon: widget.leftIcon,
              rightIcon: widget.rightIcon,
            ),
            if (!widget.hideSecondIcon)
              Padding(
                padding: EdgeInsets.only(top: 15.0.sp),
                child: CommonButton(
                  borderRadius: 20.0.sp,
                  height: 43.0.sp,
                  bottomSpace: 0,
                  label: widget.buttonTextSecond ?? "Cancel",
                  labelTextStyle: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(
                        color: AppColors.grey414651,
                        fontSize: 15.0.sp,
                        fontFamily: Fonts.sfProSemiboldDisplay,
                      ),
                  onTap:
                      widget.onTapSecondButton ??
                      () {
                        CommonMethods.goBack();
                      },
                  enabledColor: AppColors.white,
                  borderColor: AppColors.borderColorE6E7EA,
                  isEnabled: true,
                  leftIcon: widget.leftIcon,
                  rightIcon: widget.rightIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.item});

  final String item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20.sp,
            height: 20.sp,
            decoration:  BoxDecoration(
              color: AppColors.teal1A9E6E,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 12.sp),
          ),
          SizedBox(width: 10.sp),
          Expanded(
            child: CommonText(
              item,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.black242E49,
                fontSize: 14.sp,
                fontFamily: Fonts.sfProRegularDisplay,
                height: 1.3.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
