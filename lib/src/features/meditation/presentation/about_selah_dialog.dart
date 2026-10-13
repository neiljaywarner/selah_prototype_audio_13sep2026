import 'package:flutter/material.dart';

import 'widgets/licensing_attribution_sheet.dart';

/// Tasteful, peaceful modal dialog displaying Selah app credits, version info,
/// copyright transparency (specifically distinguishing proprietary NIV from public domain),
/// release notes, and publisher licensing links.
class AboutSelahDialog extends StatelessWidget {
  const AboutSelahDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final openLicensing = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AboutSelahDialog(),
    );

    if (openLicensing == true && context.mounted) {
      await LicensingAttributionSheet.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: const Color(0xFF161536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade700.withValues(alpha: 0.5)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
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
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                          'Scripture Audio Meditation • v0.3.1 (Build 42)',
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
              const SizedBox(height: 18),
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
                      _buildSectionTitle('Created With Care', Icons.favorite_rounded),
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

                      // Scripture Copyright Transparency Section
                      _buildSectionTitle('Scripture Copyrights & Attributions', Icons.verified_user_rounded),
                      const SizedBox(height: 8),
                      _buildCopyrightCard(
                        title: 'New International Version® (NIV®)',
                        badgeText: 'COPYRIGHTED · NOT PUBLIC DOMAIN',
                        badgeColor: const Color(0xFFFBBF24),
                        body: 'The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.® '
                            'Used by Permission. All rights reserved worldwide.\n\n'
                            'Audio: The Listener’s Bible®: NIV® Edition Audio ℗ 2011 by Max McLean. Used by permission.\n\n'
                            'Delivered on-demand via API.Bible with active Fair Use Message System (FUMS) reporting. '
                            'Per publisher licensing terms, proprietary audio streams are never saved or cached to disk.',
                      ),
                      const SizedBox(height: 10),
                      _buildCopyrightCard(
                        title: 'Berean Standard Bible (BSB)',
                        badgeText: 'PUBLIC DOMAIN',
                        badgeColor: Colors.greenAccent,
                        body: 'The Holy Bible, Berean Standard Bible (BSB) text and narrator audio (narrated by Barry Hays) '
                            'are dedicated to the public domain by the Berean Bible. '
                            'Free to quote, memorize, loop, and distribute without restriction.',
                      ),
                      const SizedBox(height: 10),
                      _buildCopyrightCard(
                        title: 'World English Bible (WEB)',
                        badgeText: 'PUBLIC DOMAIN',
                        badgeColor: Colors.greenAccent,
                        body: 'The World English Bible (WEB) text is in the public domain. '
                            'New Testament dramatized audio ℗ 2013 Hosanna / Faith Comes By Hearing. Used by permission.',
                      ),
                      const SizedBox(height: 20),

                      // Release Notes Section
                      _buildSectionTitle('Release Notes (v0.3.1)', Icons.auto_awesome_rounded),
                      const SizedBox(height: 8),
                      _buildReleaseBullet('Natural Voice Synthesis: Google Speech Services & Neural voice matching for peaceful contemplative cadence on NIV excerpts.'),
                      _buildReleaseBullet('Top 12 Contemplative Passages: Full WhisperX acoustic silence calibration across Matt 11, 1 Cor 13, Rom 8, Psalm 23, Psalm 62, Col 1, Psalm 91, John 3, Phil 4, Prov 3, Isa 40, and Rom 12.'),
                      _buildReleaseBullet('Interactive Community Feedback: Seamless in-app feedback submission to private GitHub triage queue and Doorbell.io.'),
                      _buildReleaseBullet('Repetition Meditation: Custom repetition looping with 4-second prayer silence gaps.'),
                      _buildReleaseBullet('Full Copyright Transparency: Explicit distinction between licensed publisher streams and public domain scriptures.'),
                      const SizedBox(height: 20),

                      // Publisher Licensing Sheet Button
                      _buildSectionTitle('Publisher Terms & Details', Icons.gavel_rounded),
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
                        onPressed: () => Navigator.of(context).pop(true),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyrightCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
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
