import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/colors.dart';
import '../../../widgets/k_widgets.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/safe_bottom.dart';
import '../../../widgets/toast.dart';
import '../today_controller.dart';

Future<void> showEditTodaySheet() {
  return Get.bottomSheet<void>(
    const _EditTodaySheet(),
    isScrollControlled: true,
  );
}

/// Drag to reorder Today's cards, switch off the ones you don't want.
/// The dose card always stays on top.
class _EditTodaySheet extends StatefulWidget {
  const _EditTodaySheet();

  @override
  State<_EditTodaySheet> createState() => _EditTodaySheetState();
}

class _EditTodaySheetState extends State<_EditTodaySheet> {
  final TodayController _c = Get.find<TodayController>();
  late final List<String> _order = _c.cardOrder;
  late final Set<String> _hidden = {..._c.tracker.todayHidden};

  String _label(String id) => TodayCard.all.firstWhere((c) => c.id == id).label;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: k.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.sp)),
        ),
        padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 8.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(height: 14.sp),
            Text(
              'Edit Today',
              style: AppText.h1.copyWith(fontSize: 24.sp, color: k.text),
            ),
            SizedBox(height: 4.sp),
            Text(
              'Drag to reorder. Switch off what you don’t need. Your next dose always stays on top.',
              style: AppText.small.copyWith(
                fontSize: 13.5.sp,
                height: 1.4,
                color: k.muted,
              ),
            ),
            SizedBox(height: 12.sp),
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                onReorderStart: (_) => Haptics.instance.selectionClick(),
                // onReorderItem already adjusts `to` for the removed item.
                onReorderItem: (from, to) {
                  setState(() {
                    _order.insert(to, _order.removeAt(from));
                  });
                  Haptics.instance.lightImpact();
                },
                children: [
                  for (var i = 0; i < _order.length; i++)
                    Padding(
                      key: ValueKey(_order[i]),
                      padding: EdgeInsets.only(bottom: 8.sp),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(6.sp, 4.sp, 8.sp, 4.sp),
                        decoration: BoxDecoration(
                          color: k.card,
                          borderRadius: BorderRadius.circular(18.sp),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: SizedBox(
                                width: 44.sp,
                                height: 44.sp,
                                child: Icon(
                                  PhosphorIconsBold.dotsSixVertical,
                                  size: 20.sp,
                                  color: k.faint,
                                  semanticLabel: 'Drag',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _label(_order[i]),
                                style: AppText.bodyStrong.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _hidden.contains(_order[i])
                                      ? k.faint
                                      : k.text,
                                ),
                              ),
                            ),
                            Semantics(
                              toggled: !_hidden.contains(_order[i]),
                              label: 'Show ${_label(_order[i])}',
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Haptics.instance.selectionClick();
                                  final id = _order[i];
                                  setState(
                                    () => _hidden.contains(id)
                                        ? _hidden.remove(id)
                                        : _hidden.add(id),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(6.sp),
                                  child: KSwitch(value: !_hidden.contains(_order[i])),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.sp),
            KBottomPadding(
              child: PillButton(
                label: 'Save',
                icon: PhosphorIconsBold.check,
                onPressed: () async {
                  await _c.saveLayout(_order, _hidden);
                  popRoute();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
