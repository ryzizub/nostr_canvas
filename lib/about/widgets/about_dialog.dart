import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A dialog that shows information about Nostr Canvas.
class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: NesContainer(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DialogHeader(),
                const SizedBox(height: 16),
                const _AboutNostrSection(),
                const SizedBox(height: 16),
                const _HowToUseSection(),
                const SizedBox(height: 16),
                const _CreditsSection(),
                const SizedBox(height: 16),
                NesButton(
                  type: NesButtonType.normal,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/logo.jpeg',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nostr Canvas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Collaborative Pixel Canvas',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _AboutNostrSection extends StatelessWidget {
  const _AboutNostrSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'About Nostr'),
        SizedBox(height: 8),
        Text(
          'Nostr is a decentralized protocol for censorship-resistant '
          'social applications. Each pixel you place is a cryptographically '
          'signed event, making your art permanent and verifiable.',
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

class _HowToUseSection extends StatelessWidget {
  const _HowToUseSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'How to Use'),
        SizedBox(height: 8),
        _BulletPoint(text: 'Select a color using the palette button'),
        _BulletPoint(text: 'Click on the canvas to place a pixel'),
        _BulletPoint(text: 'Use inspect mode to view pixel details'),
        _BulletPoint(text: 'Toggle grid for precise placement'),
        _BulletPoint(text: 'Proof-of-Work cooldown prevents spam'),
      ],
    );
  }
}

class _CreditsSection extends StatelessWidget {
  const _CreditsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Credits'),
        SizedBox(height: 8),
        _BulletPointWithLink(
          text: 'Created by ryzizub - ',
          linkText: 'ryzizub.com',
          url: 'https://ryzizub.com',
        ),
        _BulletPointWithLink(
          text: 'Source code on ',
          linkText: 'GitHub',
          url: 'https://github.com/ryzizub/nostr_canvas',
        ),
        _BulletPoint(text: 'Built with Flutter'),
        _BulletPoint(text: 'Powered by Nostr Protocol'),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '- ',
            style: TextStyle(fontSize: 10),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPointWithLink extends StatelessWidget {
  const _BulletPointWithLink({
    required this.text,
    required this.linkText,
    required this.url,
  });

  final String text;
  final String linkText;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '- ',
            style: TextStyle(fontSize: 10),
          ),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 10),
                ),
                GestureDetector(
                  onTap: () => _launchUrl(url),
                  child: Text(
                    linkText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
