// Pixel art stays sharp (docs/design/pets.md §2.10, §11): the size helpers round every
// art pixel to a whole number of device pixels at each device pixel ratio. The
// built-in packs (鲸娘, Deepy) are gone with the brand cleanup; the size
// arithmetic here is tested on whatever pack is on disk.

import 'dart:math' as math;

import 'package:dsh_app/pets/pet_pack.dart';
import 'package:dsh_app/pets/pet_state.dart';
import 'package:dsh_app/ui/pets/pet_sprite.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const ratios = [2.0, 2.625, 2.75, 3.0, 3.5];

void main() {
  test('sizes: whole device pixels, the three always differ', () {
    for (final dpr in ratios) {
      for (final pack in [deepy, girl]) {
        final ks = [for (final s in PetSize.presets) petDevicePixels(pack, s, dpr)];
        expect(ks[0] < ks[1] && ks[1] < ks[2], isTrue, reason: '${pack.id} at $dpr: $ks');
        // Standard is the doc's formula (round(30 dp × dpr ÷ body)) unless
        // that equals small.
        final standard = (30 * dpr / pack.contentBox.height).round();
        if (standard > ks[0]) expect(ks[1], standard);
      }
    }
  });

  test('自定义 rounds its own height to whole device pixels', () {
    for (final dpr in ratios) {
      for (final pack in [deepy, girl]) {
        for (final dp in [15.0, 30.0, 45.0, 90.0]) {
          final k = petDevicePixels(pack, PetSize.custom, dpr, customHeight: dp);
          expect(k, math.max(1, (dp * dpr / pack.contentBox.height).round()), reason: '${pack.id} at $dpr, $dp dp');
          expect(petScale(pack, PetSize.custom, dpr, customHeight: dp), k / dpr);
        }
      }
    }
  });

  test('the out-of-app overlay uses the same k: pinned here and in PetPackTest.kt', () {
    // The floating pet (Kotlin PetPack.screenScale / devicePixels) must draw
    // at these numbers too, else it is a size off from the chat page. The
    // same table is asserted in
    // app/android/app/src/test/kotlin/io/github/ccch1mneyyy/dsh_app/pet/PetPackTest.kt
    // (`screenScaleMatchesTheAppForTheShippedPacks`): change one, change both.
    const expected = [
      ('whale-girl', 2.0, [1, 2, 3]),
      ('whale-girl', 2.625, [1, 2, 3]),
      ('whale-girl', 2.75, [1, 2, 3]),
      ('whale-girl', 3.0, [1, 2, 3]),
      ('whale-girl', 3.5, [2, 3, 4]),
      ('deepy-whale', 2.0, [2, 3, 4]),
      ('deepy-whale', 2.625, [3, 4, 5]),
      ('deepy-whale', 2.75, [3, 4, 5]),
      ('deepy-whale', 3.0, [3, 4, 5]),
      ('deepy-whale', 3.5, [4, 5, 6]),
    ];
    final packs = {'whale-girl': girl, 'deepy-whale': deepy};
    for (final (id, dpr, ks) in expected) {
      final pack = packs[id]!;
      expect([for (final s in PetSize.presets) petDevicePixels(pack, s, dpr)], ks, reason: '$id at $dpr×');
    }
  });
}
