import 'package:adaptive_test_plus/adaptive_test_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final configuration = AdaptiveTestConfiguration.instance
    ..setLocalizedDeviceVariants(
      {iPhone8, desktop},
      const [Locale('en'), Locale('ar')],
    );

  testAdaptiveWidgets(
    'applies size and locale',
    (tester, variant) async {
      final view = tester.view;
      expect(view.physicalSize, variant.physicalSize);
      expect(view.devicePixelRatio, variant.pixelDensity);
      expect(tester.platformDispatcher.locale, variant.locale);
      expect(tester.platformDispatcher.platformBrightness, Brightness.light);
    },
  );

  testAdaptiveThemedWidgets(
    'applies platform brightness',
    (tester, variant) async {
      final expected = variant.themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light;

      expect(tester.platformDispatcher.platformBrightness, expected);
      expect(tester.platformDispatcher.locale, variant.locale);
    },
  );

  testAdaptiveWidgets(
    'variantOverride is respected',
    (tester, variant) async {
      expect(variant.name, 'pixel_9');
    },
    variantOverride: WindowVariant({pixel9}),
  );

  test('themed variant has light and dark copies of each locale', () {
    expect(configuration.themedDeviceVariant.windowConfigs, hasLength(8));
  });
}
