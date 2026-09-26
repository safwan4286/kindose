import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/colors.dart';
import '../../services/theme/theme.dart';
import '../../widgets/k_widgets.dart';
import 'report_data.dart';
import '../../widgets/toast.dart';
import '../../widgets/safe_bottom.dart';

/// On-screen version of the report so the user can check it before sharing.
/// Receives a [ReportData] as the route argument.
class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final k = context.k;
    return Scaffold(
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Row(
                children: [
                  BackCircle(onTap: () => popRoute()),
                  Expanded(child: Center(child: Text('Preview', style: AppText.h2))),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: args is! ReportData
                  ? Center(child: Text('Nothing to preview', style: AppText.title.copyWith(color: k.muted)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20)],
                          ),
                          child: DefaultTextStyle(
                            style: AppText.bodyText.copyWith(color: AppColors.ink),
                            child: _Paper(r: args),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.r});

  final ReportData r;

  static const Color _muted = Color(0xFF5E5C7A);

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t, style: AppText.title.copyWith(color: AppColors.violet)),
      );

  Widget _row(String a, String b) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE4E2F3)))),
        child: Row(
          children: [
            Expanded(child: Text(a)),
            Text(b, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _empty(String t) => Text(t, style: const TextStyle(color: _muted));

  @override
  Widget build(BuildContext context) {
    final s = r.sections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GLP-1 treatment summary', style: AppText.h3.copyWith(color: AppColors.ink)),
        const SizedBox(height: 6),
        if (r.patientName != null && r.patientName!.isNotEmpty)
          Text('Patient: ${r.patientName}${(r.patientDob ?? '').isEmpty ? '' : ', born ${r.patientDob}'}'),
        Text('Period: ${r.period}'),
        if (r.medicineLine.isNotEmpty) Text('Medicine: ${r.medicineLine}'),
        if (s.doses) ...[
          _title('Doses (${r.doses.length})'),
          if (r.doses.isEmpty) _empty('No doses logged in this period.'),
          for (final d in r.doses) _row(r.doseLine(d), ''),
        ],
        if (s.weight) ...[
          _title('Weight'),
          if (r.weights.isEmpty) _empty('No weigh-ins in this period.'),
          if (r.weights.isNotEmpty) ...[
            _row('First', '${r.weight(r.weights.first.kg)} ${r.unit}'),
            _row('Latest', '${r.weight(r.weights.last.kg)} ${r.unit}'),
            if (r.weightChange != null) _row('Change', r.weightChange!),
          ],
        ],
        if (s.sideEffects) ...[
          _title('Side effects'),
          _row('Days with a check-in', '${r.checkInDays}'),
          if (r.symptoms.isEmpty) _empty('No symptoms logged.'),
          for (final sc in r.symptoms) _row(sc.label, '${sc.days} ${sc.days == 1 ? 'day' : 'days'}'),
        ],
        if (s.nutrition) ...[
          _title('Protein & water'),
          if (r.loggedDays == 0) _empty('No food or water logged.'),
          if (r.loggedDays > 0) ...[
            _row('Average protein', '${r.avgProtein} g'),
            _row('Days at goal', '${r.proteinDaysHit} of ${r.loggedDays}'),
            _row('Average water', '${(r.avgWaterMl / 1000).toStringAsFixed(1)} L'),
          ],
        ],
        if (s.notes && r.notes.isNotEmpty) ...[
          _title('My notes'),
          for (final n in r.notes) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(n)),
        ],
        const SizedBox(height: 16),
        Text(
          'Logged by the patient in Kindose. Not a medical record or device.',
          style: AppText.tiny.copyWith(color: _muted),
        ),
      ],
    );
  }
}
