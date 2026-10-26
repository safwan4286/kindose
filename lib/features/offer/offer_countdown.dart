import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../resources/colors.dart';
import '../../services/responsiveness/device_manager.dart';
import '../../services/theme/theme.dart';

/// Rebuilds every [period] with the time left until [endsAt] (never
/// below zero).
class OfferTicker extends StatefulWidget {
  const OfferTicker({
    super.key,
    required this.endsAt,
    required this.builder,
    this.period = const Duration(seconds: 1),
  });

  final DateTime endsAt;
  final Duration period;
  final Widget Function(BuildContext context, Duration left) builder;

  @override
  State<OfferTicker> createState() => _OfferTickerState();
}

class _OfferTickerState extends State<OfferTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    return widget.builder(context, left.isNegative ? Duration.zero : left);
  }
}

/// "18h 20m", or "42m" in the last hour.
String offerLeftShort(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m < 1 ? 1 : m}m';
  return '${h}h ${m}m';
}

/// "23:41:10".
String offerLeftClock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}'
      ':${two(d.inSeconds.remainder(60))}';
}

/// Lime pill with the live countdown, on the offer screen.
class OfferCountdown extends StatelessWidget {
  const OfferCountdown({super.key, required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = k.selectedBorder == AppColors.lime;
    final fg = dark ? AppColors.lime : AppColors.limeText;
    return OfferTicker(
      endsAt: endsAt,
      builder: (context, left) {
        final over = left == Duration.zero;
        return Semantics(
          liveRegion: false,
          label: over
              ? 'This offer has ended'
              : 'Offer ends in ${left.inHours} hours ${left.inMinutes.remainder(60)} minutes',
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.lime.withValues(alpha: 0.14)
                  : AppColors.limeSoft,
              borderRadius: BorderRadius.circular(20.sp),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsBold.timer, size: 16.sp, color: fg),
                SizedBox(width: 6.sp),
                Text(
                  over ? 'This offer has ended' : 'Ends in ',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (!over)
                  Text(
                    offerLeftClock(left),
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
