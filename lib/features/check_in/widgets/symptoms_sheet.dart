import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../resources/catalog.dart';
import '../../../resources/colors.dart';
import '../../../services/haptics/haptics.dart';
import '../../../services/responsiveness/device_manager.dart';
import '../../../services/theme/theme.dart';
import '../../../services/tracker_service.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/k_sheet.dart';
import '../../../widgets/k_widgets.dart';
import '../../../widgets/toast.dart';

/// Which side effects the check-in shows, by group, plus symptoms the
/// person types. Changes apply as they're made.
Future<void> showSymptomsSheet() {
  Haptics.instance.selectionClick();
  return Get.bottomSheet<void>(
    const _SymptomsSheet(),
    isScrollControlled: true,
  );
}

class _SymptomsSheet extends StatefulWidget {
  const _SymptomsSheet();

  @override
  State<_SymptomsSheet> createState() => _SymptomsSheetState();
}

class _SymptomsSheetState extends State<_SymptomsSheet> {
  final TrackerService _t = Get.find<TrackerService>();
  final _field = TextEditingController();

  static const int _maxCustom = 12;
  static const int _maxLength = 30;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  bool _isShown(String id) => _t.checkInShown.contains(id);

  Future<void> _save(List<String> shown, List<String> custom) =>
      _t.setCheckInSymptoms(shown: shown, custom: custom);

  Future<void> _toggle(String id) {
    Haptics.instance.selectionClick();
    final shown = [..._t.checkInShown];
    if (!shown.remove(id)) shown.add(id);
    return _save(shown, [..._t.customSymptoms]);
  }

  Future<void> _add() async {
    final name = _field.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return;
    final custom = [..._t.customSymptoms];
    final taken = {
      for (final n in custom) n.toLowerCase(),
      for (final n in Catalog.symptoms.values) n.toLowerCase(),
    };
    if (taken.contains(name.toLowerCase())) {
      showToast('$name is already on the list');
      return;
    }
    if (custom.length >= _maxCustom) {
      showToast('You can add up to $_maxCustom of your own');
      return;
    }
    Haptics.instance.lightImpact();
    _field.clear();
    await _save(
      [..._t.checkInShown, Catalog.customId(name)],
      [...custom, name],
    );
  }

  /// Removes one of the person's own symptoms, with Undo (one tap, so a
  /// slip shouldn't lose it).
  Future<void> _remove(String name) async {
    Haptics.instance.selectionClick();
    final id = Catalog.customId(name);
    final shown = [..._t.checkInShown];
    final custom = [..._t.customSymptoms];
    await _save([...shown]..remove(id), [...custom]..remove(name));
    showUndoToast('$name removed', () => _save(shown, custom));
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KSheetFrame(
      title: 'Customise symptoms',
      sub: 'Pick what shows on your check-in. Nausea is always there.',
      children: [
        Obx(() {
          _t.checkInShown.length;
          _t.customSymptoms.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (group, ids) in Catalog.symptomGroups) ...[
                SectionLabel(group),
                SizedBox(height: 8.sp),
                KGroup(
                  padded: true,
                  children: [
                    for (final id in ids)
                      SwitchRow(
                        label: Catalog.symptomLabel(id),
                        value: _isShown(id),
                        onChanged: (_) => _toggle(id),
                        padding: EdgeInsets.symmetric(vertical: 10.sp),
                      ),
                  ],
                ),
                SizedBox(height: 18.sp),
              ],
              const SectionLabel('Your own'),
              SizedBox(height: 8.sp),
              if (_t.customSymptoms.isNotEmpty) ...[
                KGroup(
                  padded: true,
                  children: [
                    for (final name in _t.customSymptoms)
                      _CustomRow(
                        name: name,
                        on: _isShown(Catalog.customId(name)),
                        onToggle: () => _toggle(Catalog.customId(name)),
                        onRemove: () => _remove(name),
                      ),
                  ],
                ),
                SizedBox(height: 10.sp),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _field,
                      maxLength: _maxLength,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      style: AppText.bodyStrong.copyWith(
                        fontSize: 14.5.sp,
                        color: k.text,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add a symptom',
                        counterText: '',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  CircleIconButton(
                    icon: PhosphorIconsBold.plus,
                    label: 'Add symptom',
                    size: 48.sp,
                    background: k.text,
                    foreground: k.bg,
                    onTap: _add,
                  ),
                ],
              ),
            ],
          );
        }),
        SizedBox(height: 18.sp),
        PillButton(label: 'Done', onPressed: () => Get.back<void>()),
      ],
    );
  }
}

/// A symptom the person typed: name, remove, and the on/off switch.
class _CustomRow extends StatelessWidget {
  const _CustomRow({
    required this.name,
    required this.on,
    required this.onToggle,
    required this.onRemove,
  });

  final String name;
  final bool on;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sp),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppText.title.copyWith(fontSize: 15.sp, color: k.text),
            ),
          ),
          CircleIconButton(
            icon: PhosphorIconsBold.trash,
            label: 'Remove $name',
            size: 36.sp,
            background: k.bg,
            foreground: AppColors.danger,
            onTap: onRemove,
          ),
          SizedBox(width: 10.sp),
          Semantics(
            toggled: on,
            label: name,
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.sp),
                child: KSwitch(value: on),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
