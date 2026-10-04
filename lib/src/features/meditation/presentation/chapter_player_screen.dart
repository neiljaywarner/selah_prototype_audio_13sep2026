import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../application/chapter_player_notifier.dart';
import '../domain/chapter_info.dart';
import 'widgets/settings_bottom_sheet.dart';

class ChapterPlayerScreen extends ConsumerStatefulWidget {
  const ChapterPlayerScreen({super.key});

  @override
  ConsumerState<ChapterPlayerScreen> createState() => _ChapterPlayerScreenState();
}

class _ChapterPlayerScreenState extends ConsumerState<ChapterPlayerScreen> {
  late final TextEditingController _searchController;
  bool _showDebugLogs = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: 'COL.1');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Map<String, String> _bookCodeMap = {
    'GEN': 'GEN',
    'GENESIS': 'GEN',
    'EXO': 'EXO',
    'EXODUS': 'EXO',
    'PSL': 'PSA',
    'PSA': 'PSA',
    'PSALM': 'PSA',
    'PSALMS': 'PSA',
    'JHN': 'JHN',
    'JOHN': 'JHN',
    'COL': 'COL',
    'COLOSSIANS': 'COL',
    'ROM': 'ROM',
    'ROMANS': 'ROM',
    'MRK': 'MRK',
    'MARK': 'MRK',
    'MAT': 'MAT',
    'MATTHEW': 'MAT',
    'LUK': 'LUK',
    'LUKE': 'LUK',
    'ACT': 'ACT',
    'ACTS': 'ACT',
    'REV': 'REV',
    'REVELATION': 'REV',
  };

  void _handleSearchSubmit(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return;

    if (raw.contains(':')) {
      AppLogger.logEvent('request_verse_selection', {'query': raw});
      _showVerseNoticeDialog(raw);
      return;
    }

    final cleaned = raw.toUpperCase();
    for (final ch in kFeaturedChapters) {
      if (cleaned == ch.reference.toUpperCase() ||
          cleaned == '${ch.bookCode}.${ch.chapterNumber}') {
        ref.read(chapterPlayerProvider.notifier).loadChapter(ch);
        return;
      }
    }

    String bookCode = 'COL';
    int chapterNumber = 1;
    String bookName = 'Colossians';

    final normalized = raw.replaceAll('.', ' ').trim();
    final parts = normalized.split(RegExp(r'\s+'));

    if (parts.isNotEmpty) {
      final possibleBook = parts[0].toUpperCase();
      bookCode =
          _bookCodeMap[possibleBook] ??
          (possibleBook.length >= 3 ? possibleBook.substring(0, 3) : 'COL');
      bookName = possibleBook[0] + possibleBook.substring(1).toLowerCase();
    }

    if (parts.length >= 2) {
      chapterNumber = int.tryParse(parts[1]) ?? 1;
    }

    AppLogger.logEvent('request_chapter', {
      'query': raw,
      'parsed_code': bookCode,
      'chapter': chapterNumber,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching "$bookCode $chapterNumber" live from API.Bible...'),
        backgroundColor: const Color(0xFF1E1B4B),
        duration: const Duration(seconds: 2),
      ),
    );

    ref
        .read(chapterPlayerProvider.notifier)
        .fetchAndPlayApiBibleChapter(
          bookCode: bookCode,
          chapterNumber: chapterNumber,
          bookName: bookName,
        );
  }

  void _showVerseNoticeDialog(String userQuery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 22),
            SizedBox(width: 8),
            Text('v0.3 Preview', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Text(
          'Specific verse selection ("$userQuery") and synchronized Karaoke text highlighting arrive in v0.3!\n\nFor v0.2, Selah streams complete chapters via API.Bible REST API.',
          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: Color(0xFFFBBF24))),
          ),
        ],
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E26),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFFBBF24)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF0F0E26), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELAH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                Text(
                  'Scripture Audio Meditation',
                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDebugLogs ? Icons.bug_report : Icons.bug_report_outlined,
              color: _showDebugLogs ? Colors.greenAccent : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showDebugLogs = !_showDebugLogs;
              });
            },
            tooltip: 'Toggle Debug Console',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFFBBF24)),
            onPressed: _openSettingsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /* Search Bar */
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: _handleSearchSubmit,
                      decoration: InputDecoration(
                        hintText: 'Lookup Chapter (e.g. COL.1, John 1, Psalm 23)',
                        filled: true,
                        fillColor: const Color(0xFF1E1B4B),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.indigo),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleSearchSubmit(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Play', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /* Preset Selection Chips */
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kFeaturedChapters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chapter = kFeaturedChapters[index];
                    final isSelected = playerState.currentChapter.reference == chapter.reference;
                    return ChoiceChip(
                      label: Text(chapter.reference),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFF1E1B4B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => notifier.loadChapter(chapter),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              /* Error Notification Banner */
              if (playerState.lastError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          playerState.lastError!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              /* Main Player Display Card */
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      playerState.currentChapter.reference,
                      style: GoogleFonts.newsreader(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playerState.activeTranslation} via API.Bible',
                      style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          playerState.currentChapter.textContent,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.newsreader(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SliderTheme(
                      data: const SliderThemeData(
                        activeTrackColor: Color(0xFFFBBF24),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Color(0xFFFBBF24),
                        trackHeight: 4,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        min: 0,
                        max: playerState.duration.inMilliseconds.toDouble() > 0
                            ? playerState.duration.inMilliseconds.toDouble()
                            : 1.0,
                        value: playerState.position.inMilliseconds.toDouble().clamp(
                          0.0,
                          playerState.duration.inMilliseconds.toDouble() > 0
                              ? playerState.duration.inMilliseconds.toDouble()
                              : 1.0,
                        ),
                        onChanged: (val) => notifier.seek(Duration(milliseconds: val.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerState.position),
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                          Text(
                            _formatDuration(playerState.duration),
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: playerState.isPausedInGap
                                      ? const Color(0xFFFBBF24)
                                      : (playerState.isPlaying ? Colors.greenAccent : Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                playerState.isPausedInGap
                                    ? 'Silent Gap (${playerState.pauseGapSeconds}s)...'
                                    : (playerState.isPlaying
                                          ? 'Meditating (${playerState.processingStateName})'
                                          : 'Ready (${playerState.processingStateName})'),
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            'Loop ${playerState.currentIteration} of ${playerState.repetitions == -1 ? "∞" : playerState.repetitions}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        playerState.isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFFBBF24))
                            : GestureDetector(
                                onTap: notifier.togglePlayPause,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x40FBBF24),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    playerState.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 38,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),

              /* Live Diagnostic Log Console */
              if (_showDebugLogs) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09081A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Diagnostic Console',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 4),
                      Text(
                        'Target Bible ID: ${playerState.activeTranslation == "WEB" ? kWebAudioBibleId : kBsbAudioBibleId}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      Text(
                        'Audio Stream: ${playerState.currentChapter.audioStreamUrl}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: AppLogger.logs.length,
                          itemBuilder: (ctx, idx) {
                            final log = AppLogger.logs[idx];
                            final isErr = log.contains('🔴');
                            return Text(
                              log,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: isErr ? Colors.redAccent : Colors.white70,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
