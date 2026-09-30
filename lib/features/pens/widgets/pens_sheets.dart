import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/supply/supply_service.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_date_picker.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_text_field.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/press_scale.dart';

/// Result of the set-up sheet.
class PackSetup {
  const PackSetup({
    required this.perPack,
    required this.left,
    required this.spare,
  });

  final int perPack;
  final int left;
  final int spare;
}

/// Result of the settings sheet.
class PackSettings {
  const PackSettings({required this.perPack, required this.currency});

  final int perPack;
  final String currency;
}

/// Currencies offered in settings. The saved one is added if missing.
const List<String> _currencies = [
  r'$',
  '£',
  '€',
  r'C$',
  r'A$',
  r'NZ$',
  '₹',
  'AED',
];

/// "How many doses in one pen, how many left, how many spare?"
Future<PackSetup?> showPackSetupSheet({
  required String pack,
  required String dosesWord,
  required int perPack,
  required int spare,
  int? left,
}) {
  return Get.bottomSheet<PackSetup>(
    _SetupSheet(
      pack: pack,
      dosesWord: dosesWord,
      perPack: perPack,
      left: left ?? perPack,
      spare: spare,
    ),
    isScrollControlled: true,
  );
}

/// Doses per pen and currency.
Future<PackSettings?> showPackSettingsSheet({
  required String pack,
  required String dosesWord,
  required int perPack,
  required String currency,
}) {
  return Get.bottomSheet<PackSettings>(
    _SettingsSheet(
      pack: pack,
      dosesWord: dosesWord,
      perPack: perPack,
      currency: currency,
    ),
    isScrollControlled: true,
  );
}

/// A new purchase. Returns null when dismissed.
Future<Purchase?> showPurchaseSheet({
  required String pack,
  required String currency,
  double? strengthMg,
}) {
  return Get.bottomSheet<Purchase>(
    _PurchaseSheet(pack: pack, currency: currency, strengthMg: strengthMg),
    isScrollControlled: true,
  );
}

// ------------------------------------------------------------------ set up

class _SetupSheet extends StatefulWidget {
  const _SetupSheet({
    required this.pack,
    required this.dosesWord,
    required this.perPack,
    required this.left,
    required this.spare,
  });

  final String pack;
  final String dosesWord;
  final int perPack;
  final int left;
  final int spare;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  late int _perPack = widget.perPack;
  late int _left = widget.left.clamp(0, widget.perPack);
  late int _spare = widget.spare;

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    return KSheetFrame(
      title: 'Your $pack',
      sub: 'Three quick numbers. After this, it counts down each time you log.',
      children: [
        StepperRow(
          label: '${_cap(widget.dosesWord)} in one $pack',
          sub: 'Check the box or your leaflet',
          value: _perPack,
          min: 1,
          max: 60,
          onChanged: (v) => setState(() {
            _perPack = v;
            _left = _left.clamp(0, v);
          }),
        ),
        SizedBox(height: 8.sp),
        StepperRow(
          label: 'Left in the $pack you’re using',
          value: _left,
          min: 0,
          max: _perPack,
          onChanged: (v) => setState(() => _left = v),
        ),
        SizedBox(height: 8.sp),
        StepperRow(
          label: 'Spare ${pack}s at home',
          sub: 'Unopened',
          value: _spare,
          min: 0,
          max: 99,
          onChanged: (v) => setState(() => _spare = v),
        ),
        SizedBox(height: 18.sp),
        PillButton(
          label: 'Save',
          onPressed: () => Navigator.of(
            context,
          ).pop(PackSetup(perPack: _perPack, left: _left, spare: _spare)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- settings

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.pack,
    required this.dosesWord,
    required this.perPack,
    required this.currency,
  });

  final String pack;
  final String dosesWord;
  final int perPack;
  final String currency;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int _perPack = widget.perPack;
  late String _currency = widget.currency;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final options = [
      ..._currencies,
      if (!_currencies.contains(widget.currency)) widget.currency,
    ];
    return KSheetFrame(
      title: 'Settings',
      children: [
        StepperRow(
          label: '${_cap(widget.dosesWord)} in one ${widget.pack}',
          value: _perPack,
          min: 1,
          max: 60,
          onChanged: (v) => setState(() => _perPack = v),
        ),
        SizedBox(height: 16.sp),
        Text(
          'Currency',
          style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
        ),
        SizedBox(height: 8.sp),
        Wrap(
          spacing: 8.sp,
          runSpacing: 8.sp,
          children: [
            for (final c in options)
              KChip(
                label: c,
                selected: c == _currency,
                onTap: () {
                  Haptics.instance.selectionClick();
                  setState(() => _currency = c);
                },
              ),
          ],
        ),
        SizedBox(height: 18.sp),
        PillButton(
          label: 'Save',
          onPressed: () => Navigator.of(
            context,
          ).pop(PackSettings(perPack: _perPack, currency: _currency)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- purchase

class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({
    required this.pack,
    required this.currency,
    this.strengthMg,
  });

  final String pack;
  final String currency;
  final double? strengthMg;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  final TextEditingController _price = TextEditingController();
  final TextEditingController _note = TextEditingController();
  DateTime _date = Dates.dateOnly(DateTime.now());
  int _packs = 1;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _priceValue {
    final v = double.tryParse(_price.text.trim().replaceAll(',', ''));
    return v == null || v < 0 || v > 10000000 ? null : v;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showKDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      title: 'When did you buy it?',
    );
    if (d != null && mounted) setState(() => _date = Dates.dateOnly(d));
  }

  void _save() {
    final price = _priceValue;
    if (price == null) return;
    Haptics.instance.mediumImpact();
    final mg = widget.strengthMg;
    final note = _note.text.trim();
    Navigator.of(context).pop(
      Purchase(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        // Noon, so the month never shifts with the time zone.
        date: _date.add(const Duration(hours: 12)),
        packs: _packs,
        price: price,
        strengthMg: mg == null || mg <= 0 ? null : mg,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final pack = widget.pack;
    final mg = widget.strengthMg;
    final valid = _priceValue != null && _price.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: KSheetFrame(
        title: 'Add a purchase',
        sub: mg == null || mg <= 0
            ? 'For your own records.'
            : 'For your own records. Strength: ${Catalog.mg(mg)} mg.',
        children: [
          PressScale(
            onTap: _pickDate,
            semanticLabel: 'Date, ${Dates.shortWithDay(_date)}. Tap to change.',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
              decoration: BoxDecoration(
                color: k.card,
                borderRadius: BorderRadius.circular(18.sp),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date',
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                  ),
                  Text(
                    Dates.sameDay(_date, DateTime.now())
                        ? 'Today'
                        : Dates.shortWithDay(_date),
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 14.5.sp,
                      color: k.text,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  PhosphorIcon(
                    PhosphorIconsBold.calendarBlank,
                    size: 17.sp,
                    color: k.muted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.sp),
          StepperRow(
            label: '${_cap(pack)}s bought',
            value: _packs,
            min: 1,
            max: 99,
            onChanged: (v) => setState(() => _packs = v),
          ),
          SizedBox(height: 14.sp),
          Text(
            'Total paid',
            style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
          ),
          SizedBox(height: 8.sp),
          Row(
            children: [
              Container(
                height: 56.sp,
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: k.card,
                  borderRadius: BorderRadius.circular(16.sp),
                ),
                child: Text(
                  widget.currency,
                  style: AppText.h2.copyWith(fontSize: 20.sp, color: k.text),
                ),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: KTextField(
                  controller: _price,
                  hint: '0',
                  large: true,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          KTextField(
            controller: _note,
            hint: 'Where from (optional)',
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: 12.sp),
          PillButton(label: 'Add purchase', onPressed: valid ? _save : null),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ shared

/// A card row with a label and −/+ buttons around a number.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.sub,
  });

  final String label;
  final String? sub;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  void _step(int by) {
    final next = value + by;
    if (next < min || next > max) return;
    Haptics.instance.selectionClick();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      label: label,
      // Flutter needs a value whenever increase/decrease are set.
      value: '$value',
      increasedValue: value < max ? '${value + 1}' : null,
      decreasedValue: value > min ? '${value - 1}' : null,
      onIncrease: value < max ? () => _step(1) : null,
      onDecrease: value > min ? () => _step(-1) : null,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.sp, 10.sp, 10.sp, 10.sp),
        decoration: BoxDecoration(
          color: k.card,
          borderRadius: BorderRadius.circular(18.sp),
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.title.copyWith(
                        fontSize: 15.sp,
                        color: k.text,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        style: AppText.small.copyWith(
                          fontSize: 12.5.sp,
                          color: k.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            StepButtons(
              value: value,
              onMinus: value > min ? () => _step(-1) : null,
              onPlus: value < max ? () => _step(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// −  value  + with a small pop on the number when it changes.
class StepButtons extends StatelessWidget {
  const StepButtons({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.showValue = true,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  /// False when the number is shown elsewhere (just − and +).
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleIconButton(
          icon: PhosphorIconsBold.minus,
          label: 'Less',
          onTap: onMinus,
          size: 38.sp,
          background: k.cardAlt,
        ),
        if (!showValue)
          SizedBox(width: 6.sp)
        else
          SizedBox(
            width: 42.sp,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                textAlign: TextAlign.center,
                style: AppText.h2.copyWith(fontSize: 20.sp, color: k.text),
              ),
            ),
          ),
        CircleIconButton(
          icon: PhosphorIconsBold.plus,
          label: 'More',
          onTap: onPlus,
          size: 38.sp,
          background: k.cardAlt,
        ),
      ],
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
