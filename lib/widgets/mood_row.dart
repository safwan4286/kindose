import 'package:flutter/material.dart';

import '../resources/catalog.dart';
import '../resources/colors.dart';
import '../services/theme/theme.dart';
import 'k_widgets.dart';

/// Five 3D faces. The chosen one grows and gets a border.
class MoodRow extends StatelessWidget {
  const MoodRow({
    super.key,
    required this.selected,
    required this.onPick,
    this.height = 72,
    this.onCard = true,
  });

  final int? selected;
  final ValueChanged<int> onPick;
  final double height;

  /// True when shown inside a card, so unselected tiles blend in.
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      children: [
        for (var i = 0; i < Catalog.moods.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: selected == i,
              label: Catalog.moods[i].label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: height,
                  decoration: BoxDecoration(
                    color: selected == i ? k.selectedBg : (onCard ? k.card : k.card),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == i ? k.selectedBorder : (onCard ? k.card : k.card),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: selected == i ? 1.18 : 1,
                        child: ThreeD(Catalog.moods[i].icon, size: height * 0.44),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Catalog.moods[i].label,
                        style: AppText.tiny.copyWith(
                          color: k.textSoft,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Asks for a number with a text field.
/// Returns null when cancelled and `double.nan` when the user taps Clear.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  required double min,
  required double max,
  bool allowClear = false,
}) async {
  final result = await showDialog<_NumberResult>(
    context: context,
    builder: (_) => _NumberDialog(
      title: title,
      unit: unit,
      initial: initial,
      min: min,
      max: max,
      allowClear: allowClear,
    ),
  );
  if (result == null) return null;
  if (result.cleared) return double.nan;
  return result.value;
}

class _NumberResult {
  const _NumberResult(this.value, {this.cleared = false});

  final double? value;
  final bool cleared;
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.unit,
    required this.initial,
    required this.min,
    required this.max,
    required this.allowClear,
  });

  final String title;
  final String unit;
  final double? initial;
  final double min;
  final double max;
  final bool allowClear;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.toStringAsFixed(widget.initial! % 1 == 0 ? 0 : 1),
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.').trim());
    if (v == null || v < widget.min || v > widget.max) {
      setState(() => _error =
          'Enter a number from ${widget.min.toStringAsFixed(0)} to ${widget.max.toStringAsFixed(0)}');
      return;
    }
    Navigator.of(context).pop(_NumberResult(v));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: AppText.h3),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          suffixText: widget.unit,
          errorText: _error,
          fillColor: context.k.cardAlt,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        if (widget.allowClear)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _NumberResult(null, cleared: true)),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
