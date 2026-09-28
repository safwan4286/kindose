import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:printing/printing.dart';

import '../../resources/colors.dart';
import '../../resources/date_utils.dart';
import '../../services/plus/plus_access.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/k_widgets.dart';
import '../../widgets/safe_bottom.dart';
import '../../widgets/toast.dart';
import 'report_controller.dart';
import 'report_data.dart';
import 'report_pdf.dart';

/// The real PDF, rendered on screen (pinch to zoom). Free users can show
/// it at the visit; sharing needs Plus. Receives a [ReportData] argument.
class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({super.key});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final RxBool _sharing = false.obs;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final args = Get.arguments;
    return Scaffold(
      backgroundColor: k.cardAlt,
      body: KSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 8.sp),
              child: Row(
                children: [
                  BackCircle(onTap: popRoute),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Your report', style: AppText.h2.copyWith(fontSize: 22.sp, color: k.text)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: args is! ReportData
                  ? Center(child: Text('Nothing to preview', style: AppText.title.copyWith(color: k.muted)))
                  : PdfPreview(
                      build: (_) => ReportPdf.build(args),
                      useActions: false,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      pdfFileName: 'kindose-report-${Dates.key(DateTime.now())}.pdf',
                      scrollViewDecoration: BoxDecoration(color: k.cardAlt),
                      pdfPreviewPageDecoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), blurRadius: 16)],
                      ),
                      loadingWidget: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            if (args is ReportData)
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 8.sp, 20.sp, 12.sp),
                child: Obx(() => PillButton(
                      label: PlusAccess.active.value ? 'Share PDF' : 'Share PDF · Plus',
                      icon: PhosphorIconsBold.shareNetwork,
                      busy: _sharing.value,
                      onPressed: () => ReportController.share(args, _sharing),
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
