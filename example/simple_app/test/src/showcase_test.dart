import 'package:adaptive_test_plus/adaptive_test_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_app_example/src/showcase_app.dart';

final _devices = {iPhone16, pixel9};

void main() {
  group('Themed and localized goldens', () {
    testAdaptiveThemedWidgets(
      '$ShowcaseApp render',
      (tester, variant) async {
        await tester.pumpWidget(
          AdaptiveWrapper(
            windowConfig: variant,
            tester: tester,
            child: const ShowcaseApp(),
          ),
        );

        await tester.expectGolden<ShowcaseApp>(variant);
      },
      variantOverride: WindowVariant({
        for (final device in _devices)
          for (final locale in showcaseLocales) ...[
            device.light().withLocale(locale),
            device.dark().withLocale(locale),
          ],
      }),
    );
  });
}
