import 'package:flutter/material.dart';
import 'package:nestflow/nestflow.dart';

extension AppColorsExtension on BuildContext {
  AppColors get colors => isDark ? AppDarkColors() : AppLightColors();

  AppLightColors get lightColors => AppLightColors();

  AppColors get darkColors => AppDarkColors();
}
