// ignore_for_file: avoid-long-functions

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dart extension to add an await images function to a [WidgetTester] object,
/// e.g. [awaitImages];
extension AwaitImages on WidgetTester {
  /// Pauses test until images are ready to be rendered.
  ///
  /// Images that only appear once other images are loaded (e.g. after a
  /// placeholder) are awaited too: the lookup is repeated while new images
  /// show up, at most [maxPasses] times.
  Future<void> awaitImages({int maxPasses = 3}) async {
    final awaited = <Element>{};
    for (var pass = 0; pass < maxPasses; pass++) {
      final elements = _imageElements();
      if (pass > 0 && elements.every(awaited.contains)) {
        return;
      }
      awaited.addAll(elements);
      await _awaitImagesOnce();
    }
  }

  List<Element> _imageElements() {
    try {
      return [
        ...find.byType(Image, skipOffstage: false).evaluate(),
        ...find.byType(FadeInImage, skipOffstage: false).evaluate(),
        ...find.byType(DecoratedBox, skipOffstage: false).evaluate(),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _awaitImagesOnce() async {
    await runAsync(() async {
      for (final element
          in find.byType(Image, skipOffstage: false).evaluate().toList()) {
        try {
          final widget = element.widget as Image;
          final image = widget.image;
          await precacheImage(image, element);
          await pump();
        } catch (e) {
          debugPrint('An image could not be precached by awaitImages: $e');
        }
      }

      for (final element in find
          .byType(FadeInImage, skipOffstage: false)
          .evaluate()
          .toList()) {
        try {
          final widget = element.widget as FadeInImage;
          final image = widget.image;
          final pumpDurationInMilliseconds = max(
            widget.fadeInDuration.inMilliseconds,
            widget.fadeOutDuration.inMilliseconds,
          );
          await precacheImage(image, element);
          await pump(Duration(milliseconds: pumpDurationInMilliseconds));
        } catch (e) {
          debugPrint('An image could not be precached by awaitImages: $e');
        }
      }

      for (final element in find
          .byType(DecoratedBox, skipOffstage: false)
          .evaluate()
          .toList()) {
        try {
          final widget = element.widget as DecoratedBox;
          final decoration = widget.decoration;
          final image = switch (decoration) {
            BoxDecoration() => decoration.image?.image,
            ShapeDecoration() => decoration.image?.image,
            _ => null,
          };
          if (image != null) {
            await precacheImage(image, element);
            await pump();
          }
        } catch (e) {
          debugPrint('An image could not be precached by awaitImages: $e');
        }
      }
    });
  }
}
