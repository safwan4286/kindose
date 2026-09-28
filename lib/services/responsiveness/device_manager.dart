import 'dart:math';
import 'package:flutter/material.dart';

extension ScreenSize on num {
  double get sp => DeviceManager.instance.setSp(toDouble());
}

class DeviceManager {
  // Singleton
  static DeviceManager? _instance;

  DeviceManager._internal();

  static DeviceManager get instance {
    _instance ??= DeviceManager._internal();
    return _instance!;
  }

  // Design reference (base screen size)
  double width = 380.0;
  double height = 800.0;
  bool allowFontScaling = true;

  static double? _screenWidth;
  static double? _screenHeight;
  static double? _pixelRatio;
  static double? _statusBarHeight;
  static double? _bottomBarHeight;
  static double? _textScaleFactor;

  void init(BuildContext context) => initWith(MediaQuery.of(context));

  /// Same as [init] but from explicit data (the app builder passes the
  /// width-limited MediaQuery used on tablets).
  void initWith(MediaQueryData mediaQuery) {
    // _mediaQueryData = mediaQuery;
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _pixelRatio = mediaQuery.devicePixelRatio;
    _statusBarHeight = mediaQuery.padding.top;
    _bottomBarHeight = mediaQuery.padding.bottom;
    _textScaleFactor = mediaQuery.textScaler.scale(1);
  }

  double get scaleFactor {
    if (_screenWidth == null || _screenHeight == null) return 1.0;

    final referenceDiagonal = sqrt(width * width + height * height);
    final actualDiagonal = sqrt(
      _screenWidth! * _screenWidth! + _screenHeight! * _screenHeight!,
    );
    // Clamped: phones scale a little either way; tablets keep phone sizes
    // (the app is shown in a centred phone-width column there).
    return (actualDiagonal / referenceDiagonal).clamp(minScale, maxScale);
  }

  static const double minScale = 0.85;
  static const double maxScale = 1.15;

  double setWidth(double width) =>
      _screenWidth != null ? width * (_screenWidth! / this.width) : width;

  double setHeight(double height) =>
      _screenHeight != null ? height * (_screenHeight! / this.height) : height;

  double setSp(double fontSize) {
    final factor = scaleFactor;
    if (_textScaleFactor == null || _textScaleFactor == 0) {
      return fontSize * factor;
    }

    return allowFontScaling
        ? fontSize * factor
        : (fontSize * factor) / _textScaleFactor!;
  }

  // Optional getters
  double get screenWidth => _screenWidth ?? width;

  double get screenHeight => _screenHeight ?? height;

  double get pixelRatio => _pixelRatio ?? 1.0;

  double get statusBarHeight => _statusBarHeight ?? 0.0;

  double get bottomBarHeight => _bottomBarHeight ?? 0.0;

  double get textScale => _textScaleFactor ?? 1.0;
}

extension CustomPadding on Widget {
  Padding addPadding({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: top ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
        right: right ?? 0,
      ),
      child: this,
    );
  }
}
