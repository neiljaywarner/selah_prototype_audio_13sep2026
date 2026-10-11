import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../core/constants/bible_canon.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/picker/bible_reference_parser.dart';
import '../../../core/preferences/user_preferences.dart';
import '../application/chapter_player_notifier.dart';
import '../domain/audio_mode.dart';
import '../domain/bible_translation.dart';
import '../domain/chapter_info.dart';
import '../domain/scripture_topic.dart';
import 'widgets/chapter_picker_dialog.dart';
import 'widgets/feature_voting_sheet.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/topic_tab_bar.dart';

const bool kEnableTopicTabs = bool.fromEnvironment('ENABLE_TOPIC_TABS', defaultValue: false);

class ChapterPlayerScreen extends ConsumerStatefulWidget {
  const ChapterPlayerScreen({super.key});

  @override
  ConsumerState<ChapterPlayerScreen> createState() => _ChapterPlayerScreenState();
}

class _ChapterPlayerScreenState extends ConsumerState<ChapterPlayerScreen> {
  late final TextEditingController _searchController;
  bool _showDebugLogs = false;
  ScriptureTopic _selectedTopic = kDefaultMeditationTopics[0];
  List<ParsedBibleReference> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: 'John 1');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (text.length >= 2 && !text.contains(':')) {
      final suggestions = BibleReferenceParser.getSuggestions(text);
      setState(() => _searchSuggestions = suggestions.take(4).toList());
    } else {
      if (_searchSuggestions.isNotEmpty) {
        setState(() => _searchSuggestions = []);
      }
    }
  }

  void _handleSearchSubmit(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return;

    setState(() => _searchSuggestions = []);

    if (raw.contains(':')) {
      // 1 Corinthians 13 is our specially curated love passage (verses 4-7) with full narrator audio
      final parsedList = BibleReferenceParser.getSuggestions(raw);
      if (parsedList.isNotEmpty && parsedList.first.book.code == '1CO' && parsedList.first.chapter == 13) {
        final match = parsedList.first;
        final refStr = '${match.book.name} 13:4-7';
        ref.read(userPreferencesProvider).saveChapter(refStr);
        ref
            .read(chapterPlayerProvider.notifier)
            .routeAndPlayChapter(
              bookCode: match.book.code,
              chapterNumber: match.chapter,
              bookName: match.book.name,
            );
        setState(() {});
        return;
      }

      AppLogger.logEvent('request_single_verse', {'query': raw});
      ref.read(userPreferencesProvider).saveChapter(raw);
      ref.read(chapterPlayerProvider.notifier).fetchAndPlaySingleVerse(raw);
      setState(() {});
      return;
    }

    final parsedList = BibleReferenceParser.getSuggestions(raw);
    if (parsedList.isNotEmpty) {
      final match = parsedList.first;
      final refStr = '${match.book.name} ${match.chapter}';
      ref.read(userPreferencesProvider).saveChapter(refStr);
      ref
          .read(chapterPlayerProvider.notifier)
          .routeAndPlayChapter(
            bookCode: match.book.code,
            chapterNumber: match.chapter,
            bookName: match.book.name,
          );
      setState(() {});
      return;
    }

    final normalized = raw.replaceAll('.', ' ').trim();
    final parts = normalized.split(RegExp(r'\s+'));

    String bookQuery = 'COL';
    int chapterNum = 1;

    if (parts.isNotEmpty) bookQuery = parts[0];
    if (parts.length >= 2) chapterNum = int.tryParse(parts[1]) ?? 1;

    final book = BibleCanon.findBook(bookQuery);
    final bookCode =
        book?.code ?? (bookQuery.length >= 3 ? bookQuery.substring(0, 3).toUpperCase() : 'COL');
    final bookName = book?.name ?? bookCode;

    if (!BibleCanon.isValidChapter(bookCode, chapterNum)) {
      final maxCh = BibleCanon.maxChapterFor(bookCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$bookName only has $maxCh chapter(s). Please choose 1—$maxCh.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final refStr = '$bookName $chapterNum';
    ref.read(userPreferencesProvider).saveChapter(refStr);
    ref
        .read(chapterPlayerProvider.notifier)
        .routeAndPlayChapter(bookCode: bookCode, chapterNumber: chapterNum, bookName: bookName);
    setState(() {});
  }

  void _openChapterPicker() => showDialog(
    context: context,
    builder: (ctx) => ChapterPickerDialog(
      onChapterSelected: (code, chapter, name) {
        final refStr = '$name $chapter';
        _searchController.text = refStr;
        setState(() => _searchSuggestions = []);
        ref.read(userPreferencesProvider).saveChapter(refStr);
        ref
            .read(chapterPlayerProvider.notifier)
            .routeAndPlayChapter(bookCode: code, chapterNumber: chapter, bookName: name);
        setState(() {});
      },
    ),
  );

  void _openFeatureVoting() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const FeatureVotingSheet(),
  );

  void _openSettingsModal() => showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1B4B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const SettingsBottomSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);
    final userPrefs = ref.watch(userPreferencesProvider);

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SELAH',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Scripture Audio Meditation v0.2',
                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade200),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_vote_rounded, color: Color(0xFFFBBF24)),
            tooltip: 'Feature Roadmap & Feedback',
            onPressed: _openFeatureVoting,
          ),
          IconButton(
            icon: Icon(
              _showDebugLogs ? Icons.bug_report : Icons.bug_report_outlined,
              color: _showDebugLogs ? Colors.greenAccent : Colors.white70,
            ),
            tooltip: 'Diagnostic Console',
            onPressed: () => setState(() => _showDebugLogs = !_showDebugLogs),
          ),
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined, color: Colors.cyanAccent),
            tooltip: 'Talker Live Logs',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TalkerScreen(talker: AppLogger.talker),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
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
              /* Search Bar & Browse Button */
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: _handleSearchSubmit,
                      decoration: InputDecoration(
                        hintText: 'Search Book & Chapter (e.g. Jn, Col 3, Ps 23)',
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: const Text('Play', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openChapterPicker,
                    icon: const Icon(Icons.menu_book_rounded, color: Color(0xFFFBBF24)),
                    tooltip: 'Browse All 66 Books',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () async {
                      final curRef = playerState.currentChapter.reference;
                      await ref.read(userPreferencesProvider).saveChapter(curRef);
                      if (context.mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved "$curRef" to recents'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFFFBBF24)),
                    tooltip: 'Save Current Chapter to Recents',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),

              /* Live Autocomplete Suggestions */
              if (_searchSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _searchSuggestions.map((suggestion) {
                      return ActionChip(
                        backgroundColor: const Color(0xFF0F0E26),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        label: Text(
                          suggestion.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          _searchController.text = suggestion.displayName;
                          _handleSearchSubmit(suggestion.displayName);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              /* Featured Presets (or Topic Tabs if enabled) - Single-row horizontal scroll */
              if (kEnableTopicTabs)
                TopicTabBar(
                  topics: kDefaultMeditationTopics,
                  selectedTopic: _selectedTopic,
                  activeReference: playerState.currentChapter.reference,
                  onTopicSelected: (topic) => setState(() => _selectedTopic = topic),
                  onChapterSelected: (chapter) {
                    _searchController.text = '${chapter.bookCode}.${chapter.chapterNumber}';
                    notifier.loadChapter(chapter);
                  },
                )
              else
                SizedBox(
                  height: 38,
                  child: Builder(
                    builder: (context) {
                      final savedList = userPrefs.savedChapters;
                      final savedSet = savedList.map((s) => s.toLowerCase().trim()).toSet();
                      final remainingPresets = kFeaturedChapters
                          .where((c) => !savedSet.contains(c.reference.toLowerCase().trim()))
                          .toList();
                      final totalCount = savedList.length + remainingPresets.length;

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: totalCount,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index < savedList.length) {
                            final refStr = savedList[index];
                            final isSelected = playerState.currentChapter.reference.toLowerCase().trim() ==
                                refStr.toLowerCase().trim();
                            return _PresetChip(
                              label: refStr,
                              isSelected: isSelected,
                              isBookmarked: true,
                              onTap: () => _handleSearchSubmit(refStr),
                            );
                          } else {
                            final chapter = remainingPresets[index - savedList.length];
                            final isSelected =
                                playerState.currentChapter.reference == chapter.reference;
                            return _PresetChip(
                              label: chapter.reference,
                              isSelected: isSelected,
                              isBookmarked: false,
                              onTap: () => notifier.loadChapter(chapter),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              /* Info Notice Banner */
              if (playerState.infoNotice != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          playerState.infoNotice!,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                    // Audio Mode Badge & Translation Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: playerState.audioMode.isNarrator
                                  ? Colors.indigo.withValues(alpha: 0.4)
                                  : const Color(0xFFFBBF24).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: playerState.audioMode.isNarrator
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFFBBF24),
                              ),
                            ),
                            child: Text(
                              playerState.audioMode.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: playerState.audioMode.isNarrator
                                    ? Colors.white
                                    : const Color(0xFFFBBF24),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Translation Segmented Toggle (BSB, WEB, NIV)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0E26),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: BibleTranslation.values.map((tr) {
                                  final isSelected = playerState.activeTranslation == tr.code;
                                  return GestureDetector(
                                    onTap: () => notifier.setTranslation(tr.code),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tr.shortLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.white54,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Shuffle Translations Toggle Button
                            Tooltip(
                              message: playerState.shuffleTranslations
                                  ? 'Translation Shuffle ON (Cycles BSB ↔ WEB ↔ NIV per repeat)'
                                  : 'Turn on Translation Shuffle across repetitions',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => notifier.toggleShuffleTranslations(),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: playerState.shuffleTranslations
                                          ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                                          : const Color(0xFF0F0E26),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: playerState.shuffleTranslations
                                            ? const Color(0xFFFBBF24)
                                            : Colors.white12,
                                        width: playerState.shuffleTranslations ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.shuffle_rounded,
                                      size: 16,
                                      color: playerState.shuffleTranslations
                                          ? const Color(0xFFFBBF24)
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                      '${playerState.translation.fullName} (${playerState.activeTranslation}) • API.Bible${playerState.shuffleTranslations ? ' • 🔀 Shuffle Active' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 16),

                    // Scripture Text View with optional Karaoke Highlighting
                    Container(
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(child: _KaraokeTextDisplay(playerState: playerState)),
                    ),
                    const SizedBox(height: 18),

                    // Progress Slider
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
                    const SizedBox(height: 14),

                    // Status Pill & Repetition Loop Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                Expanded(
                                  child: Text(
                                    playerState.isPausedInGap
                                        ? 'Silent Gap (${playerState.pauseGapSeconds}s)...'
                                        : (playerState.isPlaying ? 'Meditating...' : 'Ready'),
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    const SizedBox(height: 18),

                    // Play / Pause Button
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

              /* Live Diagnostic Log Console Drawer */
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          TextButton.icon(
                            onPressed: () {
                              final report = AppLogger.exportDiagnosticReport(
                                activeTranslation: playerState.activeTranslation,
                                currentChapter: playerState.currentChapter.reference,
                                audioMode: playerState.audioMode.name,
                              );
                              Clipboard.setData(ClipboardData(text: report));
                              AppLogger.logEvent('export_diagnostic_logs', {
                                'chapter': playerState.currentChapter.reference,
                                'translation': playerState.activeTranslation,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sanitized diagnostic logs copied to clipboard & logged.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFFBBF24)),
                            label: const Text(
                              'Copy / Send Logs',
                              style: TextStyle(fontSize: 11, color: Color(0xFFFBBF24)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 4),
                      Text(
                        'Target Audio ID: ${playerState.translation.audioBibleId}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      Text(
                        'Audio Stream: ${playerState.currentChapter.audioStreamUrl.isEmpty ? "(Dynamic via API.Bible)" : "Configured (S3 Presigned)"}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      if (playerState.translation.isLicensed) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Licensing: ${playerState.translation.fullName} (FUMS active)',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFFBBF24)),
                        ),
                      ],
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

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isBookmarked = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF3730A3).withValues(alpha: 0.8),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isBookmarked) ...[
                const Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 6),
              ] else if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KaraokeTextDisplay extends StatelessWidget {
  const _KaraokeTextDisplay({required this.playerState});

  final dynamic playerState;

  @override
  Widget build(BuildContext context) {
    final text = playerState.currentChapter.textContent as String;
    if (playerState.highlightEnd > playerState.highlightStart &&
        playerState.highlightEnd <= text.length) {
      final before = text.substring(0, playerState.highlightStart);
      final word = text.substring(playerState.highlightStart, playerState.highlightEnd);
      final after = text.substring(playerState.highlightEnd);

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.newsreader(
            fontSize: 15,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.87),
          ),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: word,
              style: const TextStyle(
                backgroundColor: Color(0xFFFBBF24),
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.newsreader(
        fontSize: 15,
        height: 1.5,
        color: Colors.white.withValues(alpha: 0.87),
      ),
    );
  }
}

