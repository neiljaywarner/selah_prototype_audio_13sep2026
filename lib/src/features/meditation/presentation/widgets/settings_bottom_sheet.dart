import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/esv/esv_passage_policy.dart';
import '../../../../core/preferences/user_preferences.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/remote_config/remote_config_service.dart';
import '../../application/chapter_player_notifier.dart';
import '../../domain/bible_translation.dart';
import 'emoji_feedback_dialog.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);
    final policy = ref.watch(esvPassagePolicyProvider);
    final experimentalNarrator = ref.watch(experimentalApiBibleNarratorProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);
    final knobOptions = remoteConfig.parsedKnobOptions;
    final variantGroup = knobOptions.length > 5 ? 'slider_1_to_25' : 'curated_1_3_7_inf';

    return SafeArea(
      maintainBottomViewPadding: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meditation Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          Text(
            policy.useEsvForPassages ? 'PASSAGE TEXT (ESV)' : 'BIBLE TRANSLATION',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (policy.useEsvForPassages)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Curated passages and verse search use Crossway ESV human narrator audio (David Cochran Heath).',
                style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.35),
              ),
            ),
          Row(
            children: policy.selectableTranslations.map((item) {
              final isSel = state.activeTranslation == item.code;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setTranslation(item.code),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xFF818CF8) : Colors.white10,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.coverageLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSel ? Colors.white.withValues(alpha: 0.9) : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            state.translation.copyright,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
          if (isEsvApiConfigured && kEnableExperimentalApiBibleDevFlag) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Preview: API.Bible narrator translations',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
              subtitle: const Text(
                'Experimental BSB / WEB / NIV human audio and WhisperX clips. '
                'Turn off to stay on ESV passage text only.',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
              value: experimentalNarrator,
              activeThumbColor: const Color(0xFFFBBF24),
              onChanged: (enabled) async {
                await ref.read(experimentalApiBibleNarratorProvider.notifier).setEnabled(enabled);
                if (!enabled && isEsvApiConfigured) {
                  notifier.setTranslation(BibleTranslation.esv.code, force: true);
                }
              },
            ),
          ],
          const SizedBox(height: 16),

          const Text(
            'CATALOG TIER & SCRIPTURE LIBRARY',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: CatalogTier.values.map((tier) {
              final activeTier = ref.watch(catalogTierProvider);
              final isSel = activeTier == tier;
              return Expanded(
                child: GestureDetector(
                  key: Key('settings_catalog_tier_${tier.name}'),
                  onTap: () {
                    ref.read(catalogTierProvider.notifier).setTier(tier);
                    AppLogger.logEvent('select_catalog_tier', {'tier': tier.name});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xFF818CF8) : Colors.white10,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tier.emoji} ${tier.label}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tier == CatalogTier.curated12
                              ? '12 Top Passages'
                              : tier == CatalogTier.biblical40
                                  ? '40 Wilderness'
                                  : tier == CatalogTier.softLaunch77
                                      ? 'The 77 Cohort'
                                      : 'All 66 Books',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 8,
                            color: isSel ? Colors.white.withValues(alpha: 0.9) : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            'CHAPTER REPETITIONS',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (knobOptions.length <= 5)
            Row(
              children: knobOptions.map((r) {
                final isSel = state.repetitions == r;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      notifier.setRepetitions(r);
                      AppLogger.logEvent('select_knob_value', {
                        'selected_repetitions': r,
                        'knob_variant_group': variantGroup,
                        'source': 'settings_bottom_sheet',
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          r == -1 ? '∞' : '${r}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: knobOptions.length,
                separatorBuilder: (_, index) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  final r = knobOptions[idx];
                  final isSel = state.repetitions == r;
                  return GestureDetector(
                    onTap: () {
                      notifier.setRepetitions(r);
                      AppLogger.logEvent('select_knob_value', {
                        'selected_repetitions': r,
                        'knob_variant_group': variantGroup,
                        'source': 'settings_bottom_sheet_slider',
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xFF818CF8) : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          r == -1 ? '∞' : '${r}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          const Text(
            'SILENT REFLECTION GAP',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [0, 3, 5, 10].map((s) {
              final isSel = state.pauseGapSeconds == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setPauseGap(s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${s}s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Karaoke Text Highlighting', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
              'Word-synchronized highlighting',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            value: state.karaokeEnabled,
            activeThumbColor: const Color(0xFFFBBF24),
            onChanged: (val) {
              notifier.toggleKaraoke(val);
            },
          ),
          SwitchListTile(
            key: const Key('settings_wip_features_tile'),
            title: Row(
              children: [
                const Expanded(
                  child: Text('Show Work-in-Progress Features', style: TextStyle(fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 16, color: Color(0xFFFBBF24)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'About Preview & Experimental Features',
                  onPressed: () => _showPreviewInfoDialog(context),
                ),
              ],
            ),
            subtitle: const Text(
              'Enable community feature voting, custom passage looping, and preview tools',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            value: ref.watch(workInProgressFeaturesProvider),
            activeThumbColor: const Color(0xFFFBBF24),
            onChanged: (val) {
              ref.read(workInProgressFeaturesProvider.notifier).setEnabled(val);
            },
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('open_feedback_dialog_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFBBF24),
                side: const BorderSide(color: Color(0xFFFBBF24)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Text('🕊️', style: TextStyle(fontSize: 16)),
              label: const Text('Prayer, Reflection & Feedback'),
              onPressed: () {
                final refStr = state.currentChapter.reference;
                final transCode = state.translation.code;
                final rootNav = Navigator.of(context, rootNavigator: true);
                rootNav.pop();
                EmojiFeedbackDialog.show(
                  rootNav.context,
                  currentChapter: refStr,
                  translation: transCode,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showPreviewInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161536),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.science_outlined, color: Color(0xFFFBBF24), size: 24),
            SizedBox(width: 10),
            Text('Preview & Beta Features', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selah is actively expanding acoustic Scripture coverage:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _infoBullet('Curated Passages', '1 Cor 13, Matt 11, Rom 8, Psalm 23, Psalm 62, Col 1 are pre-aligned with millisecond WhisperX precision.'),
            const SizedBox(height: 8),
            _infoBullet('Custom Verse Ranges', 'Any custom verse range within aligned chapters loops seamlessly. Other chapters play full narrator audio or TTS.'),
            const SizedBox(height: 8),
            _infoBullet('Request from Devs', 'Tapping "Request from Devs" alerts our team via GitHub & Analytics to prioritize aligning that passage next.'),
            const SizedBox(height: 8),
            _infoBullet('Community Voting', 'Vote on upcoming features like playlists, offline downloads, and new translations.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoBullet(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 13, fontWeight: FontWeight.bold)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA78BFA))),
                TextSpan(text: description, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
