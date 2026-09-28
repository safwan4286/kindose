import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../resources/colors.dart';
import '../services/haptics/haptics.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';
import 'buttons.dart';
import 'k_text_field.dart';

/// Bottom sheet that asks for one number ("Tap the number to type it").
/// Returns null when dismissed and `double.nan` when the user taps Clear.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  required double min,
  required double max,
  bool allowClear = false,
  int decimals = 1,
}) {
  String fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : decimals);
  return _showSheet(
    context,
    title: title,
    allowClear: allowClear,
    rangeHint: 'Enter ${fmt(min)} to ${fmt(max)} $unit',
    fields: [
      _FieldSpec(
        unit: unit,
        initial: initial == null ? '' : fmt(initial),
        decimals: decimals,
      ),
    ],
    parse: (texts) {
      final v = double.tryParse(texts.first.replaceAll(',', '.').trim());
      if (v == null || v < min || v > max) return null;
      return v;
    },
  );
}

/// Same sheet with two fields for height in feet and inches. Returns the
/// total in inches.
Future<double?> askFeetInches(
  BuildContext context, {
  required String title,
  double? initialInches,
  required double minInches,
  required double maxInches,
}) {
  final total = initialInches?.round();
  return _showSheet(
    context,
    title: title,
    allowClear: false,
    rangeHint:
        'Enter ${minInches ~/ 12}′ ${(minInches % 12).round()}″ to ${maxInches ~/ 12}′ ${(maxInches % 12).round()}″',
    fields: [
      _FieldSpec(
        unit: 'ft',
        initial: total == null ? '' : '${total ~/ 12}',
        decimals: 0,
      ),
      _FieldSpec(
        unit: 'in',
        initial: total == null ? '' : '${total % 12}',
        decimals: 0,
      ),
    ],
    parse: (texts) {
      final ft = int.tryParse(texts[0].trim());
      final inch = int.tryParse(
        texts[1].trim().isEmpty ? '0' : texts[1].trim(),
      );
      if (ft == null || inch == null || inch > 11) return null;
      final v = (ft * 12 + inch).toDouble();
      if (v < minInches || v > maxInches) return null;
      return v;
    },
  );
}

class _FieldSpec {
  const _FieldSpec({
    required this.unit,
    required this.initial,
    required this.decimals,
  });

  final String unit;
  final String initial;
  final int decimals;
}

Future<double?> _showSheet(
  BuildContext context, {
  required String title,
  required bool allowClear,
  required String rangeHint,
  required List<_FieldSpec> fields,
  required double? Function(List<String>) parse,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.k.bg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.sp)),
    ),
    builder: (_) => _NumberSheet(
      title: title,
      allowClear: allowClear,
      rangeHint: rangeHint,
      fields: fields,
      parse: parse,
    ),
  );
}

class _NumberSheet extends StatefulWidget {
  const _NumberSheet({
    required this.title,
    required this.allowClear,
    required this.rangeHint,
    required this.fields,
    required this.parse,
  });

  final String title;
  final bool allowClear;
  final String rangeHint;
  final List<_FieldSpec> fields;
  final double? Function(List<String>) parse;

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final List<TextEditingController> _ctrls = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];
  bool _showError = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _value => widget.parse([for (final c in _ctrls) c.text]);

  void _save() {
    final v = _value;
    if (v == null) {
      Haptics.instance.heavyImpact();
      setState(() => _showError = true);
      return;
    }
    Haptics.instance.lightImpact();
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, 16.sp + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.sp,
              height: 5.sp,
              decoration: BoxDecoration(
                color: k.border,
                borderRadius: BorderRadius.circular(3.sp),
              ),
            ),
          ),
          SizedBox(height: 16.sp),
          Text(
            widget.title,
            style: AppText.h2.copyWith(fontSize: 24.sp, color: k.text),
          ),
          SizedBox(height: 14.sp),
          Row(
            children: [
              for (var i = 0; i < widget.fields.length; i++) ...[
                if (i > 0) SizedBox(width: 10.sp),
                Expanded(
                  child: KTextField(
                    controller: _ctrls[i],
                    autofocus: i == 0,
                    large: true,
                    suffix: widget.fields[i].unit,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.fields[i].decimals > 0,
                    ),
                    textInputAction: i == widget.fields.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        widget.fields[i].decimals > 0
                            ? RegExp(r'^\d{0,4}([.,]\d{0,2})?')
                            : RegExp(r'^\d{0,3}'),
                      ),
                    ],
                    onChanged: (_) {
                      if (_showError) setState(() => _showError = false);
                    },
                    onSubmitted: (_) =>
                        i == widget.fields.length - 1 ? _save() : null,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.sp),
          Padding(
            padding: EdgeInsets.only(left: 4.sp),
            child: Text(
              widget.rangeHint,
              style: AppText.small.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: _showError ? AppColors.danger : k.faint,
              ),
            ),
          ),
          SizedBox(height: 16.sp),
          PillButton(
            label: 'Save',
            icon: PhosphorIconsBold.check,
            onPressed: _save,
          ),
          if (widget.allowClear)
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(double.nan),
                child: Text(
                  'Clear',
                  style: AppText.title.copyWith(
                    fontSize: 15.sp,
                    color: k.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
