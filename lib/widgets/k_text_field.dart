import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// The app's text input: white rounded field, ink focus ring (lime in dark
/// mode), optional unit suffix. Set [large] for numbers such as "3.75 mg".
class KTextField extends StatelessWidget {
  const KTextField({
    super.key,
    required this.controller,
    this.hint,
    this.suffix,
    this.large = false,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final bool large;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final radius = BorderRadius.circular(16.sp);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength == null
          ? null
          : MaxLengthEnforcement.enforced,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: k.text,
      style: large
          ? AppText.h1.copyWith(
              fontSize: 22.sp,
              letterSpacing: -0.4,
              color: k.text,
            )
          : AppText.bodyText.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: k.text,
            ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.bodyText.copyWith(fontSize: 16.sp, color: k.faint),
        suffixText: suffix,
        suffixStyle: AppText.title.copyWith(fontSize: 15.sp, color: k.muted),
        counterText: '',
        filled: true,
        fillColor: k.card,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.sp,
          vertical: 16.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: k.selectedBorder, width: 2),
        ),
      ),
    );
  }
}
