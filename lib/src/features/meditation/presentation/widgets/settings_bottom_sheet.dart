import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chapter_player_notifier.dart';
import '../../domain/bible_translation.dart';
import 'emoji_feedback_dialog.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
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

          const Text(
            'BIBLE TRANSLATION',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: BibleTranslation.values.map((item) {
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
          const SizedBox(height: 16),

          const Text(
            'CHAPTER REPETITIONS',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [1, 3, 7, -1].map((r) {
              final isSel = state.repetitions == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setRepetitions(r),
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
    );
  }
}
