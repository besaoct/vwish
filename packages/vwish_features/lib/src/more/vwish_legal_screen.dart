import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../library/library_widgets.dart';
import 'app_info.dart';
import 'legal_texts.dart';

enum LegalDocument { privacy, terms }

/// The Privacy Policy or Terms of Use: a short summary card, then headed sections of
/// paragraphs and bullet lists at a comfortable reading width.
class VwishLegalScreen extends ConsumerWidget {
  const VwishLegalScreen({super.key, required this.document, required this.onBack});

  final LegalDocument document;
  final VoidCallback onBack;

  static const double _readingWidth = 680;

  static const TextStyle _paragraphStyle = TextStyle(
    fontSize: 15,
    height: 1.55,
    color: VwishColors.textSecondary,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = switch (document) {
      LegalDocument.privacy => privacyPolicyText,
      LegalDocument.terms => termsOfUseText,
    };
    final email = ref.watch(supportEmailProvider);

    return Scaffold(
      backgroundColor: VwishColors.background,
      body: VwishLibraryFrame(
        topBar: VwishLibraryTopBar(title: text.title, onBack: onBack),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = vwishLibraryInsets(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(
                top: VwishSpacing.xl,
                bottom: MediaQuery.paddingOf(context).bottom + VwishSpacing.xxl,
              ),
              children: [
                _readable(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Effective $legalEffectiveDate', style: VwishTextStyles.caption),
                      const SizedBox(height: VwishSpacing.lg),
                      if (document == LegalDocument.privacy)
                        _Summary(text.summary, icon: Icons.verified_user_rounded, color: VwishColors.success)
                      else
                        _Summary(text.summary, icon: Icons.gavel_rounded, color: VwishColors.primaryLight),
                      for (final section in text.sections) _section(section),
                      if (email != null) _section(_contact(text, email)),
                      const SizedBox(height: VwishSpacing.xxl),
                      const Text(vwishCopyright, style: VwishTextStyles.caption),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static LegalSection _contact(LegalDocumentText text, String email) =>
      LegalSection('Contact', [LegalBlock.paragraph('${text.contactPrompt} Email $email.')]);

  Widget _readable(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _readingWidth), child: child),
    );
  }

  Widget _section(LegalSection section) {
    return Padding(
      padding: const EdgeInsets.only(top: VwishSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(section.heading, style: VwishTextStyles.title),
          ),
          for (final block in section.blocks) ...[
            const SizedBox(height: VwishSpacing.sm),
            if (block.bullets case final bullets?)
              for (final (index, item) in bullets.indexed)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : VwishSpacing.sm),
                  child: _Bullet(item, style: _paragraphStyle),
                )
            else
              Text(block.text!, style: _paragraphStyle),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.text, {required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VwishSurface(
      color: VwishColors.surface,
      padding: const EdgeInsets.all(VwishSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VwishTileIcon(icon, color: color, size: 36),
          const SizedBox(width: VwishSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The short version', style: VwishTextStyles.headline),
                const SizedBox(height: VwishSpacing.xs),
                Text(text, style: VwishTextStyles.body.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.item, {required this.style});

  final LegalBullet item;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // The dot sits on the first line's centre whatever the text scale.
    final lineHeight = MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: lineHeight,
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: VwishColors.primaryLight, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (item.lead != null)
                  TextSpan(
                    text: '${item.lead}. ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: VwishColors.textPrimary),
                  ),
                TextSpan(text: item.text),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}
