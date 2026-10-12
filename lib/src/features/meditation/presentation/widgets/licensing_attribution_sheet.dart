import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/bible_translation.dart';

/// Modal bottom sheet displaying Scripture & Audio licensing attributions,
/// narrator credits, API.Bible Fair Use compliance, and offline boundaries.
class LicensingAttributionSheet extends StatelessWidget {
  const LicensingAttributionSheet({
    super.key,
    required this.translation,
  });

  final BibleTranslation translation;

  static Future<void> show(
    BuildContext context, {
    BibleTranslation translation = BibleTranslation.bsb,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => LicensingAttributionSheet(translation: translation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1B4B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    translation.isLicensed ? Icons.verified_user_rounded : Icons.public_rounded,
                    color: const Color(0xFFFBBF24),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scripture & Audio Licensing',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: translation.isLicensed
                          ? const Color(0xFFFBBF24).withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      translation.badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: translation.isLicensed ? const Color(0xFFFBBF24) : Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Text(
                'Translation: ${translation.fullName} (${translation.code})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(height: 12),
              _AttributionSection(
                title: 'Text & Scripture Rights',
                icon: Icons.menu_book_rounded,
                content: translation.copyright,
              ),
              const SizedBox(height: 14),
              _AttributionSection(
                title: 'Narrator & Audio Production',
                icon: Icons.mic_rounded,
                content: 'Narrator: ${translation.narratorCredit}\n\n${translation.audioLicensingTerms}',
              ),
              const SizedBox(height: 14),
              const _AttributionSection(
                title: 'API.Bible & FUMS Fair Use Compliance',
                icon: Icons.cloud_done_rounded,
                content:
                    'Selah utilizes API.Bible (American Bible Society) for licensed scripture data and audio delivery. '
                    'All chapter requests report Fair Use Management System (FUMS) tokens to support publisher compliance and royalties.',
              ),
              const SizedBox(height: 14),
              const _AttributionSection(
                title: 'Offline Boundaries & Local Cache',
                icon: Icons.offline_bolt_rounded,
                content:
                    'WhisperX word-level timestamp JSON alignments and structural chapter texts are bundled offline. '
                    'Proprietary audio narrations (e.g., NIV from Biblica) operate strictly as on-demand streams per licensing terms.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('close_attribution_details_button'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close Details', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttributionSection extends StatelessWidget {
  const _AttributionSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E26).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 11, height: 1.45, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
