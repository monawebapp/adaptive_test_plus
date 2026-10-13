import 'package:adaptive_test_plus/adaptive_test_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final device = WindowConfigData(
    'device',
    size: const Size(390, 844),
    pixelDensity: 3,
    safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
    keyboardSize: const Size(390, 302),
    borderRadius: BorderRadius.circular(48),
    notchSize: const Size(154, 32),
    targetPlatform: TargetPlatform.iOS,
    keyboardName: 'keyboard.png',
  );

  group('WindowConfigData', () {
    test('keeps upstream defaults', () {
      expect(device.themeMode, ThemeMode.light);
      expect(device.locale, isNull);
      expect(device.physicalSize, const Size(390, 844) * 3);
      expect(device.padding, const ViewPaddingImpl(top: 47, bottom: 34) * 3);
      expect(device.viewInsets, const ViewPaddingImpl(bottom: 302) * 3);
    });

    test('identical configs are equal', () {
      expect(device.copyWith(), device);
      expect({device, device.copyWith()}, hasLength(1));
    });

    test('light and dark suffix the name and set the theme mode', () {
      final light = device.light();
      final dark = device.dark();

      expect(light.name, 'device_light');
      expect(light.themeMode, ThemeMode.light);
      expect(dark.name, 'device_dark');
      expect(dark.themeMode, ThemeMode.dark);
      expect(dark.size, device.size);
      expect(dark.padding, device.padding);
      expect(dark.viewInsets, device.viewInsets);
      expect(dark.keyboardName, device.keyboardName);
    });

    test('theme suffix is not duplicated', () {
      expect(device.dark().dark().name, 'device_dark');
      expect(iPhone16Dark.dark().name, iPhone16Dark.name);
    });

    test('withLocale keeps the name', () {
      final localized = device.withLocale(const Locale('ar'));

      expect(localized.name, 'device');
      expect(localized.locale, const Locale('ar'));
      expect(localized, isNot(device));
      expect(localized.dark().locale, const Locale('ar'));
    });
  });
}
