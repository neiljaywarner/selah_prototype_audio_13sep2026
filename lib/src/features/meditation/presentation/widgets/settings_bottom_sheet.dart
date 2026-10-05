import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chapter_player_notifier.dart';

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Berean Standard Bible (BSB) — Full Audio Narration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
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
        ],
      ),
    );
  }
}
