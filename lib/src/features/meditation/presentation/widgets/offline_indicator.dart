import 'package:flutter/material.dart';

/// Clean, unobtrusive indicator badge showing whether audio/scripture is served
/// from local bundled offline assets, cached scripture, or live online streaming.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    required this.isOffline,
    this.isBundled = false,
    this.onTap,
  });

  final bool isOffline;
  final bool isBundled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bgColor;
    final String label;
    final String tooltip;
    final String snackBarMessage;
    final IconData icon;

    if (isBundled) {
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      label = 'Bundled';
      tooltip = 'Bundled Audio: 100% Offline Ready (Zero Cellular Data)';
      snackBarMessage =
          '🌿 Bundled Audio Active: Curated human narrator audio is loaded locally on your device (zero cellular data used).';
      icon = Icons.offline_pin_rounded;
    } else if (isOffline) {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      label = 'Cached';
      tooltip = 'Offline Mode: Scripture text/audio loaded from local storage';
      snackBarMessage =
          '📦 Offline Mode Active: Serving scripture from local cache / offline voice.';
      icon = Icons.cloud_off_rounded;
    } else {
      color = const Color(0xFF6366F1);
      bgColor = const Color(0xFF6366F1).withValues(alpha: 0.15);
      label = 'Streaming';
      tooltip = 'Online Mode: Live Audio Streaming Connected';
      snackBarMessage =
          '🌐 Online Mode Active: Streaming high-definition Scripture audio from API.Bible.';
      icon = Icons.cloud_done_rounded;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(snackBarMessage),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
