import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../resources/images.dart';
import '../services/responsiveness/device_manager.dart';

class GlobalLoaderWidget extends StatelessWidget {
  const GlobalLoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Lottie.asset(Lotties.loader, height: 160.0.sp),
      ),
    );
  }
}
