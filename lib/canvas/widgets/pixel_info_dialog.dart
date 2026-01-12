import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr/nostr.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Dialog displaying pixel metadata for inspect mode.
class PixelInfoDialog extends StatelessWidget {
  const PixelInfoDialog({
    required this.pixel,
    super.key,
  });

  final Pixel pixel;

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  String _pubkeyToNpub(String pubkey) {
    try {
      return Nip19.encodePubkey(pubkey) as String;
    } on Object {
      // Fallback to truncated hex if encoding fails
      return pubkey.substring(0, 8);
    }
  }

  String _formatDate(DateTime timestamp) {
    final year = timestamp.year;
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final npub = _pubkeyToNpub(pixel.pubkey);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: NesContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Pixel Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: _ColorPreview(color: pixel.color)),
                const SizedBox(height: 16),
                _InfoItem(
                  label: 'Position',
                  value: '(${pixel.position.x}, ${pixel.position.y})',
                ),
                const SizedBox(height: 8),
                _InfoItem(
                  label: 'Color',
                  value: _colorToHex(pixel.color),
                  onCopy: () => _copyToClipboard(
                    context,
                    _colorToHex(pixel.color),
                    'Color',
                  ),
                ),
                const SizedBox(height: 8),
                _InfoItem(
                  label: 'Date',
                  value: _formatDate(pixel.timestamp),
                ),
                const SizedBox(height: 8),
                _InfoItem(
                  label: 'Author',
                  value: npub,
                  onCopy: () => _copyToClipboard(
                    context,
                    npub,
                    'Author npub',
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: NesButton(
                    type: NesButtonType.normal,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: EdgeInsets.zero,
      child: Container(
        width: 48,
        height: 48,
        color: color,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy, size: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(value),
      ],
    );
  }
}
