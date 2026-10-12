import 'package:flutter/material.dart';

import 'widgets/licensing_attribution_sheet.dart';

/// Tasteful, peaceful modal dialog displaying Selah app credits, version info,
/// release notes, and publisher licensing links.
class AboutSelahDialog extends StatelessWidget {
  const AboutSelahDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AboutSelahDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade700.withValues(alpha: 0.5)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with glowing icon and titles
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFFBBF24)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Color(0xFF0F0E26),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELAH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Scripture Audio Meditation • v0.3.0',
                          style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Credits Section
                      _buildSectionTitle(context, 'Created With Care', Icons.favorite_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: const Text(
                          'Crafted by Neil Jay Warner, and friends and brothers and sisters in Christ.\n\n'
                          'Designed to help you dwell on God\'s Word through synchronized narrator audio, '
                          'real-time karaoke verse reflection, and prayerful silence gaps.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Release Notes Section
                      _buildSectionTitle(context, 'Release Notes (v0.3.0)', Icons.auto_awesome_rounded),
                      const SizedBox(height: 8),
                      _buildReleaseBullet('Curated Passage Audio: Sub-millisecond clipping for Matt 11:28–30, 1 Cor 13:4–7, Rom 8:31–39, Psalm 23, Psalm 62:1–2, and Col 1:1–2.'),
                      _buildReleaseBullet('Acoustic Silence Calibration: Verse boundaries verified with FFmpeg silence detection and speech velocity checks.'),
                      _buildReleaseBullet('Synchronized Karaoke Highlighting: Real-time verse tracking with theme-aware active highlighting.'),
                      _buildReleaseBullet('Contemplative Reflection: Custom repetition looping with 4-second prayer silence gaps.'),
                      _buildReleaseBullet('Multi-Translation Support: Berean Standard Bible (BSB) and World English Bible (WEB) with visible publisher licensing.'),
                      _buildReleaseBullet('Community Voice: Interactive feature voting and feedback sheet powered by Firestore and Doorbell.io.'),
                      const SizedBox(height: 20),

                      // Publisher Licensing Button
                      _buildSectionTitle(context, 'Publisher Licensing', Icons.gavel_rounded),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo.shade200,
                          side: BorderSide(color: Colors.indigo.shade400.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('View Scripture & Audio Attributions'),
                        onPressed: () {
                          final navContext = Navigator.of(context).context;
                          Navigator.of(context).pop();
                          LicensingAttributionSheet.show(navContext);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom close button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF6366F1), fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
