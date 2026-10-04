/// The Privacy Policy and Terms of Use as structured data, rendered by the legal screen.
library;

const String vwishCopyright = 'Copyright © 2026 vecvel. All rights reserved.';

const String legalEffectiveDate = '3 October 2026';

/// A paragraph, or a bulleted list when [bullets] is set.
class LegalBlock {
  const LegalBlock.paragraph(String this.text) : bullets = null;

  const LegalBlock.bullets(List<LegalBullet> this.bullets) : text = null;

  final String? text;
  final List<LegalBullet>? bullets;
}

/// One list item; [lead] is set in bold before the text.
class LegalBullet {
  const LegalBullet(this.text, {this.lead});

  final String text;
  final String? lead;
}

class LegalSection {
  const LegalSection(this.heading, this.blocks);

  final String heading;
  final List<LegalBlock> blocks;
}

class LegalDocumentText {
  const LegalDocumentText({
    required this.title,
    required this.summary,
    required this.sections,
    required this.contactPrompt,
  });

  final String title;

  /// The short version, shown first.
  final String summary;
  final List<LegalSection> sections;

  /// Lead-in for the contact line, shown only when a support email is set.
  final String contactPrompt;
}

const LegalDocumentText privacyPolicyText = LegalDocumentText(
  title: 'Privacy Policy',
  summary: 'Vwish keeps everything on your device. There are no accounts, no analytics, no ads and no '
      'tracking, and nothing you watch or type is sent to us.',
  contactPrompt: 'Questions about this policy?',
  sections: [
    LegalSection('Who we are', [
      LegalBlock.paragraph(
        'Vwish ("the app") is made by vecvel. This policy explains what the app stores, '
        'where it stores it, and when it connects to the internet.',
      ),
    ]),
    LegalSection('What Vwish stores on your device', [
      LegalBlock.paragraph('To work the way you expect, Vwish saves a few things in its own storage on your device:'),
      LegalBlock.bullets([
        LegalBullet('Watch history and resume points, so you can continue where you left off.'),
        LegalBullet(
          'Playlists and the library folders you add. Folders are saved as references to where they are; your '
          'files are never copied, moved or changed.',
        ),
        LegalBullet(
          'Per-video settings, such as subtitle and audio delay and picture adjustments, and app preferences '
          'like volume, playback speed and double-tap seek.',
        ),
        LegalBullet(
          'Your profile, if you choose to fill it in: name, email address, phone number and date of birth. '
          'Every field is optional.',
        ),
      ]),
      LegalBlock.paragraph(
        'This information stays on your device. It is not uploaded, synced or shared, and we cannot see it.',
      ),
    ]),
    LegalSection("What Vwish doesn't do", [
      LegalBlock.bullets([
        LegalBullet('No accounts or sign-in.'),
        LegalBullet('No analytics, telemetry or crash reporting.'),
        LegalBullet('No advertising and no advertising identifiers.'),
        LegalBullet('No tracking across apps or websites, and no selling or sharing of personal data.'),
      ]),
    ]),
    LegalSection('When Vwish uses the internet', [
      LegalBlock.paragraph('Vwish connects to the internet only when you ask it to:'),
      LegalBlock.bullets([
        LegalBullet(
          lead: 'Videos and streams',
          'When you open a link, Vwish fetches the video directly from that address. Like any website, the '
          'server that hosts it sees the usual details of the connection, such as your IP address, and handles '
          'them under its own policies.',
        ),
        LegalBullet(
          lead: 'Speed test',
          "The test exchanges test data directly with Cloudflare's public speed test servers "
          '(speed.cloudflare.com) to measure latency, download and upload speed. It sends no personal data, '
          'profile details or viewing history. Cloudflare sees the usual details of the connection, such as '
          'your IP address.',
        ),
        LegalBullet(
          lead: 'Stream check',
          'Contacts the address you enter, plus any address it redirects to and, for a playlist, its first '
          'quality level, to see whether the link responds and what it serves. Only a small part of a file '
          'is downloaded.',
        ),
      ]),
      LegalBlock.paragraph(
        'Files on your device that you play, inspect or browse are read on your device and are never uploaded.',
      ),
    ]),
    LegalSection('Files and permissions', [
      LegalBlock.paragraph(
        'Vwish reads only the files and folders you choose to open or add to your library, and on phones and '
        "tablets the videos you place in its own folder. It doesn't scan the rest of your storage, and it never "
        'changes, moves or deletes your videos.',
      ),
    ]),
    LegalSection('Your choices', [
      LegalBlock.bullets([
        LegalBullet('Edit or clear your profile at any time in Settings › Profile.'),
        LegalBullet(
          'Clear your watch history and resume points from Continue watching on Home, or manage saved data in '
          'Settings › Storage & history.',
        ),
        LegalBullet(
          'On phones and tablets, uninstalling Vwish removes everything it stored, and on Android so does '
          'clearing its storage in system settings.',
        ),
        LegalBullet(
          'On computers, uninstalling may leave its saved settings behind. Clear your profile in Settings › '
          'Profile and your history in Settings › Storage & history first.',
        ),
      ]),
    ]),
    LegalSection("Children's privacy", [
      LegalBlock.paragraph(
        "Vwish doesn't collect personal information from anyone, including children. Anything entered in the "
        'app stays on the device it was entered on.',
      ),
    ]),
    LegalSection('Changes to this policy', [
      LegalBlock.paragraph(
        'If this policy changes, the updated version will appear in the app with a new effective date.',
      ),
    ]),
  ],
);

const LegalDocumentText termsOfUseText = LegalDocumentText(
  title: 'Terms of Use',
  summary: 'Vwish is provided as is, for personal and evaluation use. You are responsible for what you open '
      'and play with it.',
  contactPrompt: 'Questions about these terms?',
  sections: [
    LegalSection('Agreement', [
      LegalBlock.paragraph(
        'These terms apply to your use of Vwish ("the app"), made by vecvel. By installing or '
        "using the app you agree to them. If you don't agree, please don't use the app.",
      ),
    ]),
    LegalSection('License', [
      LegalBlock.paragraph(
        'Vwish is proprietary software. $vwishCopyright You may view and test the app for personal and '
        'evaluation purposes only. You may not:',
      ),
      LegalBlock.bullets([
        LegalBullet(
          'Copy, modify, adapt, translate, distribute, sell, lease or sublicense the app or any part of it without '
          'prior written consent from vecvel.',
        ),
        LegalBullet('Reverse engineer, decompile or disassemble the app, except where applicable law allows it.'),
        LegalBullet('Remove, alter or obscure any proprietary notices, labels or marks.'),
      ]),
    ]),
    LegalSection('Your content', [
      LegalBlock.paragraph(
        'Vwish plays the files and streams you choose. You are responsible for the content you open with it and '
        "for having the rights to access and play that content. vecvel doesn't provide, host or endorse any "
        'content you play.',
      ),
      LegalBlock.paragraph(
        "Don't use Vwish to break the law, to infringe anyone's rights, or to disrupt the services you stream "
        'from or test against.',
      ),
    ]),
    LegalSection('Trademarks', [
      LegalBlock.paragraph('"Vwish", "vecvel" and associated logos are trademarks of vecvel.'),
    ]),
    LegalSection('No warranty', [
      LegalBlock.paragraph(
        'The app is provided "as is", without warranty of any kind, express or implied, including the warranties '
        'of merchantability, fitness for a particular purpose and non-infringement. Results from the built-in '
        'tools, such as speed test measurements and data usage estimates, are approximate.',
      ),
    ]),
    LegalSection('Limitation of liability', [
      LegalBlock.paragraph(
        'To the fullest extent the law allows, vecvel and the authors of the app are not liable for any claim, '
        'damages or other liability, whether in contract, tort or otherwise, arising from, out of or in '
        "connection with the app or its use. Some places don't allow certain limitations, so parts of this "
        'section may not apply to you.',
      ),
    ]),
    LegalSection('Privacy', [
      LegalBlock.paragraph('How the app handles information is described in the Privacy Policy.'),
    ]),
    LegalSection('Changes to these terms', [
      LegalBlock.paragraph(
        'These terms may change from time to time. The current version and its effective date are always '
        'available in Settings › About. If you keep using the app after a change, you accept the updated terms.',
      ),
    ]),
  ],
);
