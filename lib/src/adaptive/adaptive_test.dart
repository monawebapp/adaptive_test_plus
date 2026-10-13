import 'dart:io';

import 'package:adaptive_test_plus/src/adaptive/widgets/adaptive_wrapper.dart';
import 'package:adaptive_test_plus/src/adaptive/window_config_data/window_config_data.dart';
import 'package:adaptive_test_plus/src/adaptive/window_configuration_tester.dart';
import 'package:adaptive_test_plus/src/configuration.dart';
import 'package:adaptive_test_plus/src/helpers/await_images.dart';
import 'package:adaptive_test_plus/src/helpers/skip_test_extension.dart';
import 'package:adaptive_test_plus/src/helpers/target_platform_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// Type of [callback] that will be executed inside the Flutter test
/// environment.
///
/// Take a [WidgetTester] and a [WindowConfigData] for arguments.
typedef WidgetTesterAdaptiveCallback = Future<void> Function(
  WidgetTester widgetTester,
  WindowConfigData windowConfig,
);

/// Function wrapper around [testWidgets] that will be executed for every
/// [WindowConfigData] variant.
@isTest
void testAdaptiveWidgets(
  String description,
  WidgetTesterAdaptiveCallback callback, {
  /// If true, the test will be skipped. Defaults to false.
  /// If [enforcedTestPlatform] is defined in the [AdaptiveTestConfiguration]
  /// and [failTestOnWrongPlatform] is false, the test will be skipped if the
  /// runtime platform does not match the [enforcedTestPlatform].
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  ValueVariant<WindowConfigData>? variantOverride,
  // ignore: avoid-dynamic, argument type of testWidgets
  dynamic tags,
}) {
  final configuration = AdaptiveTestConfiguration.instance;

  _testAdaptiveWidgets(
    description,
    callback,
    variant: variantOverride ?? configuration.deviceVariant,
    applyBrightness: configuration.applyThemeModeToPlatformBrightness,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
  );
}

/// Same as [testAdaptiveWidgets], but runs every device of
/// [AdaptiveTestConfiguration.deviceVariant] twice: once in light mode and
/// once in dark mode (see [AdaptiveTestConfiguration.themedDeviceVariant]).
///
/// The platform brightness follows [WindowConfigData.themeMode], so apps
/// using [ThemeMode.system] are rendered in both modes. The theme mode is
/// also available on the `windowConfig` passed to [callback].
@isTest
void testAdaptiveThemedWidgets(
  String description,
  WidgetTesterAdaptiveCallback callback, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  ValueVariant<WindowConfigData>? variantOverride,
  // ignore: avoid-dynamic, argument type of testWidgets
  dynamic tags,
}) {
  _testAdaptiveWidgets(
    description,
    callback,
    variant: variantOverride ??
        AdaptiveTestConfiguration.instance.themedDeviceVariant,
    applyBrightness: true,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
  );
}

void _testAdaptiveWidgets(
  String description,
  WidgetTesterAdaptiveCallback callback, {
  required ValueVariant<WindowConfigData> variant,
  required bool applyBrightness,
  required bool? skip,
  required Timeout? timeout,
  required bool semanticsEnabled,
  // ignore: avoid-dynamic, argument type of testWidgets
  required dynamic tags,
}) {
  testWidgets(
    description,
    (tester) async {
      // ignore: avoid-non-null-assertion, will throw in test
      final windowConfig = variant.currentValue!;
      debugDefaultTargetPlatformOverride = windowConfig.targetPlatform;
      debugDisableShadows = false;
      tester.configureWindow(windowConfig);
      if (applyBrightness) {
        tester.configurePlatformBrightness(windowConfig);
      }
      await callback(tester, windowConfig);
      debugDisableShadows = true;
      debugDefaultTargetPlatformOverride = null;
    },
    skip: skip ?? AdaptiveTestConfiguration.instance.shouldSkipTest,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}

/// Extend [WidgetTester] with the [expectGolden] method, providing the ability
/// to assert golden matching for a given [WindowConfigData].
///
/// Golden file previews are stored within the "preview" folder.
///
/// Because adaptive rendering depends on the targeted platform, we need to make
/// sure the platform running the current test matches the
/// [enforcedTestPlatform] defined in the [AdaptiveTestConfiguration].
extension Adaptive on WidgetTester {
  /// Visual regression test for a given [WindowConfigData].
  ///
  /// The [suffix] is appended to the golden file name. It defaults to
  /// the empty string if not provided.
  ///
  /// By default, the path of the generated golden file is constructed as
  /// follows:
  /// `preview/${windowConfig.name}-${name.snakeCase}$localSuffix.png`.
  /// For localized variants, `-<locale>` is appended before the extension.
  /// The layout can be changed with
  /// [AdaptiveTestConfiguration.setGoldenFileNameFactory].
  /// If a [path] is provided, it will override this default behavior.
  ///
  /// The [byKey] argument allows the test to find the widget by its unique key,
  /// which is useful when multiple widgets of the same type are present.
  ///
  /// The [version] argument is an optional integer that can be used to
  /// differentiate historical golden files.
  ///
  /// Set [waitForImages] to `false` if you want to skip waiting for all images
  /// to load before taking the snapshot. By default, it waits for all images to
  /// load.
  ///
  /// [onDeviceSetup] runs right before the golden assertion, after images
  /// are loaded. Use it for per-device adjustments such as scrolling.
  @isTest
  Future<void> expectGolden<T>(
    WindowConfigData windowConfig, {
    String? suffix,
    String? path,
    Key? byKey,
    int? version,
    bool waitForImages = true,
    Future<void> Function(WidgetTester tester, WindowConfigData windowConfig)?
        onDeviceSetup,
  }) async {
    final enforcedTestPlatform =
        AdaptiveTestConfiguration.instance.enforcedTestPlatform;
    if (enforcedTestPlatform != null &&
        !enforcedTestPlatform.isRuntimePlatform) {
      throw Exception(
        'Runtime platform ${Platform.operatingSystem}'
        ' is not ${enforcedTestPlatform.name}',
      );
    }

    if (waitForImages) {
      await awaitImages();
    }
    await onDeviceSetup?.call(this, windowConfig);

    final key = path ??
        AdaptiveTestConfiguration.instance
            .goldenFileNameFactory(windowConfig, T, suffix);
    await expectLater(
      // Find by its type except if the widget's unique key was given.
      byKey != null ? find.byKey(byKey) : find.byType(AdaptiveWrapper),
      matchesGoldenFile(key, version: version),
    );
  }
}
