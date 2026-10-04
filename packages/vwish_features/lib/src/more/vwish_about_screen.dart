import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../library/library_actions.dart';
import '../library/library_widgets.dart';
import 'app_info.dart';
import 'legal_texts.dart';
import 'settings_widgets.dart';

/// App identity, version, the legal pages and support.
class VwishAboutScreen extends ConsumerWidget {
  const VwishAboutScreen({super.key, required this.onBack, required this.onOpenPrivacy, required this.onOpenTerms});

  final VoidCallback onBack;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;

  /// There is no mail client hand-off in the app, so tapping the address copies it.
  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) showVwishSuccess(context, 'Email address copied');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(supportEmailProvider);
    return Scaffold(
      backgroundColor: VwishColors.background,
      body: VwishLibraryFrame(
        topBar: VwishLibraryTopBar(title: 'About', onBack: onBack),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = vwishLibraryInsets(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(
                top: VwishSpacing.xxl,
                bottom: MediaQuery.paddingOf(context).bottom + VwishSpacing.xxl,
              ),
              children: [
                const _Identity(),
                const VwishLibrarySectionHeader('Legal', topSpacing: VwishSpacing.xl),
                VwishLibraryGroup(
                  children: [
                    SettingsNavRow(
                      icon: Icons.privacy_tip_rounded,
                      color: VwishColors.success,
                      title: 'Privacy Policy',
                      subtitle: 'Everything stays on your device',
                      onTap: onOpenPrivacy,
                    ),
                    SettingsNavRow(
                      icon: Icons.gavel_rounded,
                      color: VwishColors.textSecondary,
                      title: 'Terms of Use',
                      onTap: onOpenTerms,
                    ),
                  ],
                ),
                if (email != null) ...[
                  const VwishLibrarySectionHeader('Support'),
                  VwishLibraryGroup(
                    children: [
                      SettingsNavRow(
                        icon: Icons.mail_rounded,
                        color: VwishColors.cyan,
                        title: 'Contact support',
                        subtitle: email,
                        subtitleMaxLines: 1,
                        trailing: const Padding(
                          padding: EdgeInsets.all(VwishSpacing.sm),
                          child: Icon(Icons.content_copy_rounded, size: 18, color: VwishColors.textMuted),
                        ),
                        semanticLabel: 'Contact support, $email. Copy address',
                        onTap: () => _copyEmail(context, email),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: VwishSpacing.xl),
                const Text(vwishCopyright, textAlign: TextAlign.center, style: VwishTextStyles.caption),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VwishLogo(size: 76, semanticLabel: 'Vwish logo'),
        const SizedBox(height: VwishSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            'Vwish',
            style: VwishTextStyles.largeTitle.copyWith(fontSize: 24),
          ),
        ),
        const SizedBox(height: VwishSpacing.xs),
        const Text(
          'Version $vwishAppVersion (build $vwishBuildNumber)',
          style: VwishTextStyles.caption,
        ),
        const SizedBox(height: VwishSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'A fast video player for the files on your device and the streams you open. Vwish plays '
            'almost any format, remembers where you left off, and keeps your library, history and '
            'settings on your device.',
            style: VwishTextStyles.bodySecondary.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
