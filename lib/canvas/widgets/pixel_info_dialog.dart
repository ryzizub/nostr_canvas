import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr/nostr.dart';
import 'package:nostr_canvas/profile/profile.dart';
import 'package:pixel_repository/pixel_repository.dart';
import 'package:profile_repository/profile_repository.dart';

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

String _truncateNpub(String npub) {
  if (npub.length > 20) {
    return '${npub.substring(0, 12)}...${npub.substring(npub.length - 8)}';
  }
  return npub;
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

/// Dialog displaying pixel metadata for inspect mode.
class PixelInfoDialog extends StatelessWidget {
  const PixelInfoDialog({
    required this.pixel,
    super.key,
  });

  final Pixel pixel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = ProfileCubit(
          profileRepository: context.read<ProfileRepository>(),
        );
        unawaited(cubit.fetchProfile(pixel.pubkey));
        return cubit;
      },
      child: _PixelInfoDialogContent(pixel: pixel),
    );
  }
}

class _PixelInfoDialogContent extends StatelessWidget {
  const _PixelInfoDialogContent({required this.pixel});

  final Pixel pixel;

  @override
  Widget build(BuildContext context) {
    final npub = _pubkeyToNpub(pixel.pubkey);
    final colorHex = _colorToHex(pixel.color);

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
                  value: colorHex,
                  onCopy: () => _copyToClipboard(context, colorHex, 'Color'),
                ),
                const SizedBox(height: 8),
                _InfoItem(
                  label: 'Date',
                  value: _formatDate(pixel.timestamp),
                ),
                const SizedBox(height: 8),
                _AuthorSection(
                  npub: npub,
                  onCopy: () => _copyToClipboard(context, npub, 'Author npub'),
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

class _AuthorSection extends StatelessWidget {
  const _AuthorSection({
    required this.npub,
    required this.onCopy,
  });

  final String npub;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final isLoading = state.status == ProfileStatus.loading;
        final hasProfile = profile != null && profile.hasMetadata;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Author',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: const Icon(Icons.copy, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _ProfileAvatar(
                  pictureUrl: profile?.picture,
                  isLoading: isLoading,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        )
                      else if (hasProfile) ...[
                        Text(
                          profile.bestName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _truncateNpub(npub),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else
                        Text(
                          _truncateNpub(npub),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.pictureUrl,
    required this.isLoading,
  });

  final String? pictureUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 32,
        height: 32,
        child: _ProfileAvatarContent(
          pictureUrl: pictureUrl,
          isLoading: isLoading,
        ),
      ),
    );
  }
}

class _ProfileAvatarContent extends StatelessWidget {
  const _ProfileAvatarContent({
    required this.pictureUrl,
    required this.isLoading,
  });

  final String? pictureUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: NesHourglassLoadingIndicator());
    }

    if (pictureUrl != null && pictureUrl!.isNotEmpty) {
      return Image.network(
        pictureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _ProfileAvatarFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: NesHourglassLoadingIndicator());
        },
      );
    }

    return const _ProfileAvatarFallback();
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NesIcon(
        iconData: NesIcons.user,
        size: const Size.square(20),
      ),
    );
  }
}
