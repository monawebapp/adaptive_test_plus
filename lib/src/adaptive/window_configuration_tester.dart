import 'package:adaptive_test_plus/src/adaptive/window_config_data/window_config_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dart extension to add configuration functions to a [WidgetTester] object,
/// e.g. [configureWindow], [configureOpenedKeyboardWindow],
/// [configureClosedKeyboardWindow].
extension WidgetTesterWithConfigurableWindow on WidgetTester {
  /// Configure the tester window to represent the given device variant.
  void configureWindow(WindowConfigData windowConfig) {
    view.physicalSize = windowConfig.physicalSize;
    view.devicePixelRatio = windowConfig.pixelDensity;
    view.padding = windowConfig.padding;
    view.viewPadding = windowConfig.padding;

    addTearDown(view.resetPadding);
    addTearDown(view.resetViewPadding);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetViewInsets);

    final locale = windowConfig.locale;
    if (locale != null) {
      platformDispatcher
        ..localeTestValue = locale
        ..localesTestValue = [locale];
      addTearDown(platformDispatcher.clearLocaleTestValue);
      addTearDown(platformDispatcher.clearLocalesTestValue);
    }
  }

  /// Sets the platform brightness from [WindowConfigData.themeMode].
  ///
  /// [ThemeMode.system] (or null) keeps the current platform brightness.
  void configurePlatformBrightness(WindowConfigData windowConfig) {
    final brightness = switch (windowConfig.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system || null => null,
    };
    if (brightness == null) return;

    platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(platformDispatcher.clearPlatformBrightnessTestValue);
  }

  /// Configure the tester window to represent an opened keyboard on the given
  /// device variant.
  void configureOpenedKeyboardWindow(WindowConfigData windowConfig) {
    view.viewInsets = windowConfig.viewInsets;
    view.padding = windowConfig.padding.copyWith(bottom: 0);
  }

  /// Configure the tester window to represent a closed keyboard on the given
  /// device variant.
  void configureClosedKeyboardWindow(WindowConfigData windowConfig) {
    view.resetViewInsets();
    view.padding = windowConfig.padding;
  }
}
