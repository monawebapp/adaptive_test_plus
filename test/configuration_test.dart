import 'package:adaptive_test_plus/adaptive_test_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MyWidget {}

void main() {
  final configuration = AdaptiveTestConfiguration.instance;

  tearDown(configuration.reset);

  group('device variants', () {
    test('throws when not set', () {
      expect(() => configuration.deviceVariant, throwsException);
      expect(() => configuration.themedDeviceVariant, throwsException);
    });

    test('themed variant contains light and dark copies', () {
      configuration.setDeviceVariants({iPhone8, pixel9});

      expect(
        configuration.themedDeviceVariant.windowConfigs.map((e) => e.name),
        ['iPhone_8_light', 'iPhone_8_dark', 'pixel_9_light', 'pixel_9_dark'],
      );
    });

    test('themed variant follows setDeviceVariants', () {
      configuration.setDeviceVariants({iPhone8});
      expect(configuration.themedDeviceVariant.windowConfigs, hasLength(2));

      configuration.setDeviceVariants({iPhone8, desktop});
      expect(configuration.themedDeviceVariant.windowConfigs, hasLength(4));
    });

    test('localized variants combine devices and locales', () {
      configuration.setLocalizedDeviceVariants(
        {iPhone8, desktop},
        const [Locale('en'), Locale('ar')],
      );

      final variant = configuration.deviceVariant;
      expect(variant.windowConfigs, hasLength(4));
      expect(
        variant.windowConfigs.map(variant.describeValue),
        ['iPhone_8-en', 'iPhone_8-ar', 'desktop-en', 'desktop-ar'],
      );
      expect(configuration.themedDeviceVariant.windowConfigs, hasLength(8));
    });
  });

  group('describeValue', () {
    test('defaults to the device name', () {
      configuration.setDeviceVariants({iPhone8});

      expect(configuration.deviceVariant.describeValue(iPhone8), 'iPhone_8');
    });

    test('can be customized', () {
      configuration
        ..setDeviceVariants({iPhone8})
        ..setCustomDescribeValue((config) => 'custom ${config.name}');

      expect(
        configuration.deviceVariant.describeValue(iPhone8),
        'custom iPhone_8',
      );
    });
  });

  group('golden file names', () {
    test('flat factory matches adaptive_test paths', () {
      expect(
        GoldenFileNameFactories.flat(iPhone8, _MyWidget, null),
        'preview/iPhone_8-my_widget.png',
      );
      expect(
        GoldenFileNameFactories.flat(iPhone8, _MyWidget, 'withKeyboard'),
        'preview/iPhone_8-my_widget_with_keyboard.png',
      );
    });

    test('flat factory appends theme and locale for derived variants', () {
      expect(
        GoldenFileNameFactories.flat(
          iPhone8.dark().withLocale(const Locale('pt', 'BR')),
          _MyWidget,
          'home',
        ),
        'preview/iPhone_8_dark-my_widget_home-pt_BR.png',
      );
    });

    test('nested factory', () {
      expect(
        GoldenFileNameFactories.nested(iPhone8, _MyWidget, null),
        'golden/my_widget/iPhone_8.png',
      );
      expect(
        GoldenFileNameFactories.nested(
          iPhone8.light().withLocale(const Locale('ar')),
          _MyWidget,
          'with keyboard',
        ),
        'golden/my_widget/with_keyboard/ar/iPhone_8_light.png',
      );
    });

    test('default factory is flat and can be replaced', () {
      expect(
        configuration.goldenFileNameFactory(iPhone8, _MyWidget, null),
        GoldenFileNameFactories.flat(iPhone8, _MyWidget, null),
      );

      configuration.setGoldenFileNameFactory(GoldenFileNameFactories.nested);
      expect(
        configuration.goldenFileNameFactory(iPhone8, _MyWidget, null),
        'golden/my_widget/iPhone_8.png',
      );
    });
  });

  group('skip', () {
    test('does not skip by default', () {
      expect(configuration.shouldSkipTest, isFalse);
    });

    test('skipGoldenAssertion skips tests', () {
      configuration.setSkipGoldenAssertion(() => true);
      expect(configuration.shouldSkipTest, isTrue);

      configuration.setSkipGoldenAssertion(() => false);
      expect(configuration.shouldSkipTest, isFalse);
    });
  });
}
