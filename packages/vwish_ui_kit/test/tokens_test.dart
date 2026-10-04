import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_ui_kit/src/foundation/vwish_internal.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

void main() {
  test('foregroundOn picks the higher-contrast text color', () {
    expect(VwishColors.foregroundOn(VwishColors.primary), VwishColors.textPrimary);
    expect(VwishColors.foregroundOn(VwishColors.surfaceElevated), VwishColors.textPrimary);
    expect(VwishColors.foregroundOn(Colors.white), VwishColors.textOnLight);
    expect(VwishColors.foregroundOn(VwishColors.boostBand), VwishColors.textOnLight);
  });

  test('text tokens meet contrast targets on surfaces', () {
    for (final bg in [VwishColors.surface, VwishColors.surfaceElevated, VwishColors.surfaceElevatedHigher]) {
      expect(VwishColors.contrastRatio(VwishColors.textMuted, bg), greaterThanOrEqualTo(4.5));
      expect(VwishColors.contrastRatio(VwishColors.textSecondary, bg), greaterThanOrEqualTo(4.5));
    }
    expect(
      VwishColors.contrastRatio(VwishColors.primaryLight, Color.alphaBlend(VwishColors.primaryTonal, VwishColors.surface)),
      greaterThanOrEqualTo(4.5),
    );
    expect(VwishColors.contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
  });

  test('every foreground/background pair the components draw meets its contrast target', () {
    double ratio(Color fg, Color bg) => VwishColors.contrastRatio(fg, bg);
    const destructiveFill = Color(0x29EF4444);

    // Filled, text-bearing controls: primary button, selected chip and segment, secondary button.
    expect(ratio(VwishColors.foregroundOn(VwishColors.primary), VwishColors.primary), greaterThanOrEqualTo(4.5));
    expect(
      ratio(VwishColors.foregroundOn(VwishColors.surfaceElevatedHigher), VwishColors.surfaceElevatedHigher),
      greaterThanOrEqualTo(4.5),
    );
    for (final page in [VwishColors.background, VwishColors.surface, VwishColors.surfaceElevated]) {
      expect(ratio(VwishColors.primaryLight, Color.alphaBlend(VwishColors.primaryTonal, page)), greaterThanOrEqualTo(4.5));
      expect(ratio(VwishColors.errorLight, Color.alphaBlend(destructiveFill, page)), greaterThanOrEqualTo(4.5));
      expect(ratio(VwishColors.textPrimary, Color.alphaBlend(VwishColors.primarySoft, page)), greaterThanOrEqualTo(4.5));
      expect(ratio(VwishColors.errorLight, page), greaterThanOrEqualTo(4.5));
      expect(ratio(VwishColors.textSecondary, page), greaterThanOrEqualTo(4.5));
    }
    // Text fields and dropdown triggers, resting and focused/open.
    for (final fill in [VwishColors.surfaceElevatedHigher, VwishColors.fieldActive]) {
      for (final fg in [VwishColors.textPrimary, VwishColors.textSecondary, VwishColors.textMuted]) {
        expect(ratio(fg, fill), greaterThanOrEqualTo(4.5), reason: '$fg on $fill');
      }
      expect(ratio(VwishColors.primaryLight, fill), greaterThanOrEqualTo(3));
    }
  });

  test('focus outlines stay soft', () {
    expect(VwishBorders.focus.color.a, lessThanOrEqualTo(0.3));
    expect(VwishBorders.focus.width, lessThanOrEqualTo(1));
  });

  test('shadows stay soft and borders stay hairline', () {
    for (final shadow in [...VwishShadows.subtle, ...VwishShadows.soft]) {
      expect(shadow.blurRadius, greaterThanOrEqualTo(16));
      expect(shadow.spreadRadius, lessThanOrEqualTo(0));
      expect(shadow.color.a, lessThanOrEqualTo(0.35));
    }
    expect(VwishColors.border.a, lessThanOrEqualTo(0.12));
    expect(VwishColors.borderBright.a, lessThanOrEqualTo(0.12));
    expect(VwishBorders.width, inInclusiveRange(0.5, 1.0));
  });

  testWidgets('breakpoint extension follows window width', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      ctx = context;
      return const SizedBox();
    })));
    expect(ctx.isCompact, isTrue);
    expect(ctx.isMedium, isFalse);

    tester.view.physicalSize = const Size(700, 800);
    await tester.pump();
    expect(ctx.isMedium, isTrue);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pump();
    expect(ctx.isExpanded, isTrue);
  });

  test('hover, focus and press tints keep labels on filled controls at 4.5:1', () {
    const states = [
      VwishPressState(pressed: false, hovered: true, focused: false, enabled: true),
      VwishPressState(pressed: false, hovered: false, focused: true, enabled: true),
      VwishPressState(pressed: true, hovered: false, focused: false, enabled: true),
    ];
    for (final fill in [VwishColors.primary, VwishColors.surfaceElevatedHigher, VwishColors.fieldActive]) {
      final label = VwishColors.foregroundOn(fill);
      for (final state in states) {
        final tinted = vwishInteractiveFill(fill, state);
        expect(VwishColors.contrastRatio(label, tinted), greaterThanOrEqualTo(4.5), reason: '$fill $state');
      }
    }
    for (final state in states) {
      final trigger = vwishInteractiveFill(VwishColors.fieldActive, state);
      expect(VwishColors.contrastRatio(VwishColors.textSecondary, trigger), greaterThanOrEqualTo(4.5));
    }
  });

  test('Figtree is the one typeface, applied to every text style through the theme', () {
    final theme = VwishTheme.darkTheme;
    for (final style in [
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.bodySmall,
      theme.textTheme.titleLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.labelLarge,
      theme.textTheme.headlineMedium,
      theme.primaryTextTheme.bodyMedium,
    ]) {
      expect(style?.fontFamily, VwishFonts.family);
    }
    expect(VwishFonts.files, everyElement(startsWith('packages/vwish_ui_kit/fonts/Figtree-')));
  });
}
