# Adaptive Test Plus

[![pub package](https://img.shields.io/pub/v/adaptive_test_plus.svg)](https://pub.dev/packages/adaptive_test_plus)

A maintained, **drop-in compatible** continuation of
[adaptive_test](https://pub.dev/packages/adaptive_test) by
[Theodo Apps](https://apps.theodo.com), with light/dark themed and localized
golden tests on top.

![Example](https://raw.githubusercontent.com/monawebapp/adaptive_test_plus/main/doc/example.png)

### Coming from `adaptive_test`

Nothing else changes, golden file paths included:

```diff
 dev_dependencies:
-  adaptive_test: ^0.10.4
+  adaptive_test_plus: ^0.11.0
```

```diff
-import 'package:adaptive_test/adaptive_test.dart';
+import 'package:adaptive_test_plus/adaptive_test_plus.dart';
```

## Table of Contents
1. [Features](#features)
2. [Getting Started](#getting-started)
3. [Usage](#usage)
   - [Rendering Custom Fonts](#rendering-custom-fonts)
   - [Setting Up Test Devices](#setting-up-test-devices)
   - [Configuring Difference Threshold](#configuring-difference-threshold)
   - [Enforcing Test Platform](#enforcing-test-platform)
   - [Writing a Test](#writing-a-test)
   - [Light and Dark Themes](#light-and-dark-themes)
   - [Localized Goldens](#localized-goldens)
   - [Golden File Names](#golden-file-names)
   - [Skipping Goldens](#skipping-goldens)
4. [Migration Guide](#migration-guide)
5. [Additional Information](#additional-information)

## Features

Use this package in your tests to:
- Generate golden files for different devices during tests
- Load fonts
- Set window sizes and pixel density
- Await image rendering
- Render physical and system UI layers
- Render a keyboard during tests
- Set a preferred OS for running tests
- Configure a difference tolerance threshold for file comparison
- Run every test in light and dark mode
- Run every test once per locale
- Customize golden file names and test descriptions

## Getting Started

1. Add `adaptive_test_plus` to your dev dependencies.

2. Create a `flutter_test_config.dart` file at the root of your `test` folder with a `testExecutable` function:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
```

For more information, see the [official Flutter documentation](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html).

## Usage

### Rendering Custom Fonts

1. Add your fonts to your app assets folders.
2. Add your fonts to your Flutter assets in `pubspec.yaml`:

```yaml
flutter:
  fonts:
  - family: Roboto
    fonts:
      - asset: fonts/Roboto-Black.ttf
```

3. In your `flutter_test_config.dart`, call `loadFonts()`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadFonts();
  await testMain();
}
```

> ℹ️ `loadFonts()` loads fonts from `pubspec.yaml` and from every separate package dependency as well.

### Setting Up Test Devices

1. Define a set of device variants:

```dart
final defaultDeviceConfigs = {
  iPhone16,
  pixel9,
};
```

2. Use the `AdaptiveTestConfiguration` singleton to set variants:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AdaptiveTestConfiguration.instance
    ..setDeviceVariants(defaultDeviceConfigs);
  await loadFonts();
  await testMain();
}
```

### Configuring Difference Threshold

To allow for small pixel differences between processors, add `setupFileComparatorWithThreshold()` to your `flutter_test_config.dart`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AdaptiveTestConfiguration.instance
    ..setDeviceVariants(defaultDeviceConfigs);
  await loadFonts();
  setupFileComparatorWithThreshold();
  await testMain();
}
```

### Enforcing Test Platform

Configure `AdaptiveTestConfiguration` to enforce a specific test platform:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AdaptiveTestConfiguration.instance
    ..setEnforcedTestPlatform(TargetPlatform.macOS)
    ..setDeviceVariants(defaultDeviceConfigs);
  await loadFonts();
  setupFileComparatorWithThreshold();
  await testMain();
}
```

To skip tests instead of throwing an error on unintended platforms:

```dart
AdaptiveTestConfiguration.instance
  ..setEnforcedTestPlatform(TargetPlatform.macOS)
  ..setFailTestOnWrongPlatform(false)
  ..setDeviceVariants(defaultDeviceConfigs);
```

### Writing a Test

Use the `testAdaptiveWidgets` function:

```dart
void main() {
  testAdaptiveWidgets(
    'Test description',
    (tester, variant) async {
      await tester.pumpWidget(
        AdaptiveWrapper(
          windowConfig: variant,
          tester: tester,
          child: const App(),
        ),
      );

      await tester.expectGolden<App>(variant);
    },
  );
}
```

### Light and Dark Themes

`testAdaptiveThemedWidgets` runs each configured device twice, as
`<device>_light` and `<device>_dark`. The platform brightness is set
accordingly, so apps using `ThemeMode.system` render both themes. The theme
mode is also available as `variant.themeMode`.

```dart
testAdaptiveThemedWidgets(
  'Settings page',
  (tester, variant) async {
    await tester.pumpWidget(
      AdaptiveWrapper(
        windowConfig: variant,
        tester: tester,
        child: const App(), // MaterialApp(themeMode: ThemeMode.system, ...)
      ),
    );

    await tester.expectGolden<App>(variant);
  },
);
```

Single devices can be derived with `device.light()`, `device.dark()` or
`device.withThemeMode(mode)`.

To make `testAdaptiveWidgets` apply the platform brightness of dark devices
such as `iPhone16Dark` too (off by default to keep existing goldens):

```dart
AdaptiveTestConfiguration.instance.setApplyThemeModeToPlatformBrightness(true);
```

### Localized Goldens

Run every test once per device and locale. The locale is applied to the test
platform dispatcher and appended to the golden name, e.g.
`preview/iPhone_16-app-de.png`:

```dart
AdaptiveTestConfiguration.instance.setLocalizedDeviceVariants(
  defaultDeviceConfigs,
  AppLocalizations.supportedLocales,
);
```

Themed tests combine with it automatically. A single device can be localized
with `device.withLocale(const Locale('de'))`.

### Golden File Names

The default layout is unchanged: `preview/<device>-<widget>[_<suffix>].png`.
Switch layouts or provide your own:

```dart
AdaptiveTestConfiguration.instance
  // golden/<widget>/[<suffix>/][<locale>/]<device>.png
  ..setGoldenFileNameFactory(GoldenFileNameFactories.nested)
  // Test names shown in the runner
  ..setCustomDescribeValue((config) => '${config.name} ${config.themeMode?.name}');
```

`expectGolden` also accepts `onDeviceSetup`, called after images are loaded and
right before the comparison, for per-device tweaks:

```dart
await tester.expectGolden<App>(
  variant,
  onDeviceSetup: (tester, config) async {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
  },
);
```

### Skipping Goldens

Skip all adaptive tests on machines that can't reproduce your references:

```dart
AdaptiveTestConfiguration.instance
  .setSkipGoldenAssertion(() => !Platform.isMacOS);
```

## Migration Guide

<details>
<summary>Migrating from adaptive_test_extended</summary>

`adaptive_test_extended` features are available without its breaking changes:

| adaptive_test_extended | adaptive_test_plus |
| --- | --- |
| `package:adaptive_test_extended/adaptive_test_extended.dart` | `package:adaptive_test_plus/adaptive_test_plus.dart` |
| `testAdaptiveThemedWidgets` | same |
| `setLocalizedDeviceVariants(devices, locales)` | same |
| `setCustomDescribeValue` | same |
| `setSkipGoldenChecker` (skipped off macOS by default) | `setSkipGoldenAssertion` (never skips by default) |
| `fileNameFactory = ...` | `setGoldenFileNameFactory(...)`, `GoldenFileNameFactories.nested` for the same layout |
| `expectGolden(onDeviceSetup: ...)` | same |
| `homeIndicator:` | `systemNavBar: SystemNavBarData.gestureIndicator(...)` |
| Device names `Desktop`, `Pixel_5` | `desktop`, `pixel_5`: rename or regenerate those goldens |
| Implicit `golden` tag | pass `tags: ['golden']` explicitly |

</details>
<details>
<summary>Migrating to version 0.7.x</summary>
Version 0.7.0 introduces several breaking changes and new features:

1. **Breaking Change**: `loadFonts()` no longer accepts a `packages` argument. `loadFontsFromPackage()` was removed.
   - Update your `flutter_test_config.dart`:
     ```dart
     // Old
     await loadFonts('my_package');
     // or
     await loadFontsFromPackage(
       package: Package(
         name: 'my_package',
         relativePath: '../package',
       ),
     );

     // New
     await loadFonts();
     ```
   - `loadFonts()` now supports custom icon fonts like material_symbols_icons.

2. **Breaking Change**: `WindowConfigData` now includes a `keyboardName` property.
   - Update your custom device configurations to include this new property.
</details>
<details>
<summary>Migrating to version 0.5.x</summary>

Version 0.5.0 introduces a new default file name for goldens that's compatible with Windows file systems. To rename your existing golden files, use the following script:

```bash
#!/bin/bash

rename_files_in_preview() {
    find . -type d -name "preview" | while read -r dir; do
        echo "Processing directory: $dir"
        find "$dir" -type f | while read -r file; do
            new_name=$(echo "$file" | sed 's/:/-/g')
            if [ "$file" != "$new_name" ]; then
                mv "$file" "$new_name"
                echo "Renamed $file to $new_name"
            fi
        done
    done
}

rename_files_in_preview
```

Save this script as a `.sh` file and run it from your project root directory.

</details>

## Additional Information

Issues and pull requests are welcome on
[GitHub](https://github.com/monawebapp/adaptive_test_plus/issues).

This package is based on [adaptive_test](https://github.com/bamlab/adaptive_test),
created by [Theodo Apps](https://apps.theodo.com) and released under the MIT
license.


