import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../models/logs.dart';
import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../resources/date_utils.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_widgets.dart';

// ------------------------------------------------------ double-log check

enum CloseDoseChoice { editThat, logNew }

/// Asked when a new dose is close to a saved one. Returns null if closed.
Future<CloseDoseChoice?> showCloseDoseSheet(DoseLog close, {required bool daily}) {
  Haptics.instance.lightImpact();
  return Get.bottomSheet<CloseDoseChoice>(
    _CloseDoseSheet(close: close, daily: daily),
    isScrollControlled: true,
  );
}

class _CloseDoseSheet extends StatelessWidget {
  const _CloseDoseSheet({required this.close, required this.daily});

  final DoseLog close;
  final bool daily;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final ago = Dates.daysBetween(close.takenAt, DateTime.now());
    final when = switch (ago) {
      0 => 'today',
      1 => 'yesterday',
      _ => '$ago days ago',
    };
    final site = close.site.isEmpty ? '' : ' · ${Catalog.siteName(close.site).toLowerCase()}';
    final day = Dates.weekdayName(close.takenAt.weekday);
    return KSheetFrame(
      icon: const KIconTile(
        icon: PhosphorIconsBold.calendarCheck,
        bg: AppColors.amberSoft,
        fg: AppColors.amberText,
      ),
      title: daily ? 'Already marked as taken today' : 'You logged a dose $when',
      sub: '${Dates.shortWithDay(close.takenAt)}, ${Dates.time(close.takenAt)} · '
          '${Catalog.mgLabel(close.strengthMg)}$site. '
          'Is this a new dose, or do you want to fix that one?',
      children: [
        PillButton(
          label: ago <= 1 ? 'Edit that dose' : "Edit $day's dose",
          icon: PhosphorIconsBold.pencilSimple,
          onPressed: () => Navigator.of(context).pop(CloseDoseChoice.editThat),
        ),
        SizedBox(height: 4.sp),
        LinkButton(
          label: 'Log a new one anyway',
          color: k.text,
          onTap: () => Navigator.of(context).pop(CloseDoseChoice.logNew),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ change dose

class ChangeDoseResult {
  const ChangeDoseResult({required this.strength, required this.makeUsual, this.switchMedicine = false});

  final double strength;
  final bool makeUsual;
  final bool switchMedicine;
}

/// Pick the strength for this dose. Kindose only records what the
/// prescriber set; it never suggests one.
Future<ChangeDoseResult?> showChangeDoseSheet({
  required List<double> strengths,
  required double current,
  required double usual,
  required bool makeUsual,
  required String medicineName,
}) {
  return Get.bottomSheet<ChangeDoseResult>(
    _ChangeDoseSheet(
      strengths: strengths,
      current: current,
      usual: usual,
      makeUsual: makeUsual,
      medicineName: medicineName,
    ),
    isScrollControlled: true,
  );
}

class _ChangeDoseSheet extends StatefulWidget {
  const _ChangeDoseSheet({
    required this.strengths,
    required this.current,
    required this.usual,
    required this.makeUsual,
    required this.medicineName,
  });

  final List<double> strengths;
  final double current;
  final double usual;
  final bool makeUsual;
  final String medicineName;

  @override
  State<_ChangeDoseSheet> createState() => _ChangeDoseSheetState();
}

class _ChangeDoseSheetState extends State<_ChangeDoseSheet> {
  late double _pick = widget.current;
  late bool _usual = widget.makeUsual;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final changed = _pick != widget.usual;
    return KSheetFrame(
      title: 'Dose for this time',
      sub: 'Pick the ${widget.medicineName} dose your prescriber gave you.',
      children: [
        Wrap(
          spacing: 8.sp,
          runSpacing: 8.sp,
          children: [
            for (final s in widget.strengths)
              SizedBox(
                width: 98.sp,
                child: ChoiceBox(
                  selected: s == _pick,
                  semanticLabel: '${Catalog.mgLabel(s)}${s == widget.usual ? ', your usual dose' : ''}',
                  onTap: () {
                    Haptics.instance.selectionClick();
                    setState(() => _pick = s);
                  },
                  height: 56.sp,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Catalog.mgLabel(s), style: AppText.title.copyWith(fontSize: 15.sp, color: k.text)),
                      if (s == widget.usual)
                        Text('Usual', style: AppText.tiny.copyWith(fontSize: 11.sp, color: k.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: changed
              ? Padding(
                  padding: EdgeInsets.only(top: 12.sp),
                  child: SwitchRow(
                    label: 'Make this my usual dose',
                    sub: 'Use it for future doses and reminders',
                    value: _usual,
                    onChanged: (v) => setState(() => _usual = v),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        SizedBox(height: 16.sp),
        PillButton(
          label: 'Use ${Catalog.mgLabel(_pick)}',
          icon: PhosphorIconsBold.check,
          onPressed: () => Navigator.of(context).pop(ChangeDoseResult(strength: _pick, makeUsual: _usual && changed)),
        ),
        SizedBox(height: 4.sp),
        LinkButton(
          label: 'Switched medicine?',
          color: k.text,
          onTap: () => Navigator.of(context).pop(
            ChangeDoseResult(strength: _pick, makeUsual: false, switchMedicine: true),
          ),
        ),
      ],
    );
  }
}
