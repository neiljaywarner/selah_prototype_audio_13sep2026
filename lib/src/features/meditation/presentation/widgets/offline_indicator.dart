import 'package:flutter/material.dart';

/// Clean, unobtrusive indicator badge showing whether audio/scripture is served
/// from local offline bundled assets or online streaming.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    required this.isOffline,
    this.onTap,
  });

  final bool isOffline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final bgColor = isOffline
        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
        : const Color(0xFF10B981).withValues(alpha: 0.15);
    final label = isOffline ? 'Offline' : 'Online';
    final tooltip = isOffline
        ? 'Offline Mode: Bundled Human Audio & Text Active'
        : 'Online Mode: Live Audio Streaming Connected';
    final icon = isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isOffline
                        ? '🌿 Offline Mode Active: Curated human narrator audio and text are loaded locally on your device.'
                        : '🌐 Online Mode Active: Streaming high-definition Scripture audio from API.Bible.',
                  ),
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
