import 'package:flutter/material.dart';

import '../resources/catalog.dart';
import '../resources/colors.dart';
import '../services/theme/theme.dart';
import 'k_widgets.dart';

// askNumber moved to ask_number.dart; re-exported so old imports keep working.
export 'ask_number.dart';

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
                    color: selected == i
                        ? k.selectedBg
                        : (onCard ? k.card : k.card),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == i
                          ? k.selectedBorder
                          : (onCard ? k.card : k.card),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: selected == i ? 1.18 : 1,
                        child: ThreeD(
                          Catalog.moods[i].icon,
                          size: height * 0.44,
                        ),
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
