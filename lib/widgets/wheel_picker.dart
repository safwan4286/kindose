import 'package:flutter/material.dart';

import '../resources/colors.dart';
import '../services/responsiveness/device_manager.dart';
import '../services/theme/theme.dart';

/// One scroll wheel (day, month, year, hour…). Put several in a
/// [WheelPickerCard]. [selected] is an index into 0..[count)-1; when [count]
/// shrinks (e.g. 31 → 30 days) the wheel moves to stay in range.
class WheelColumn extends StatefulWidget {
  const WheelColumn({
    super.key,
    required this.count,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.semanticLabel,
  });

  final int count;
  final int selected;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;
  final String? semanticLabel;

  static double get itemExtent => 50.sp;

  @override
  State<WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<WheelColumn> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.selected);

  @override
  void didUpdateWidget(covariant WheelColumn old) {
    super.didUpdateWidget(old);
    // Follow changes made from outside (clamped day, loaded profile).
    if (_controller.hasClients && _controller.selectedItem != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.hasClients &&
            _controller.selectedItem != widget.selected) {
          _controller.animateToItem(
            widget.selected,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      label: widget.semanticLabel,
      value: widget.labelBuilder(widget.selected),
      increasedValue: widget.selected + 1 < widget.count
          ? widget.labelBuilder(widget.selected + 1)
          : null,
      decreasedValue: widget.selected > 0
          ? widget.labelBuilder(widget.selected - 1)
          : null,
      onIncrease: widget.selected + 1 < widget.count
          ? () => widget.onChanged(widget.selected + 1)
          : null,
      onDecrease: widget.selected > 0
          ? () => widget.onChanged(widget.selected - 1)
          : null,
      child: ExcludeSemantics(
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: WheelColumn.itemExtent,
          diameterRatio: 1.6,
          perspective: 0.004,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: widget.onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.count,
            builder: (context, i) {
              final on = i == widget.selected;
              return Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: AppText.h1.copyWith(
                    fontSize: on ? 24.sp : 19.sp,
                    letterSpacing: -0.4,
                    color: on ? k.text : k.faint,
                  ),
                  child: Text(widget.labelBuilder(i)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// White card holding several [WheelColumn]s side by side, with the
/// selection band and top/bottom fades. [flex] sets each column's width.
class WheelPickerCard extends StatelessWidget {
  const WheelPickerCard({
    super.key,
    required this.columns,
    this.flex,
    this.visibleItems = 5,
  });

  final List<Widget> columns;
  final List<int>? flex;
  final int visibleItems;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final extent = WheelColumn.itemExtent;
    return Container(
      height: extent * visibleItems,
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(26.sp),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 2.sp,
            offset: Offset(0, 1.sp),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: extent,
              margin: EdgeInsets.symmetric(horizontal: 10.sp),
              decoration: BoxDecoration(
                color: k.cardAlt,
                borderRadius: BorderRadius.circular(16.sp),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < columns.length; i++)
                Expanded(flex: flex?[i] ?? 1, child: columns[i]),
            ],
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    k.card,
                    k.card.withValues(alpha: 0),
                    k.card.withValues(alpha: 0),
                    k.card,
                  ],
                  stops: const [0, 0.32, 0.68, 1],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
