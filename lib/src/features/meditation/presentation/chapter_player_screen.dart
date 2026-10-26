import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../core/constants/bible_canon.dart';
import '../../../core/esv/esv_passage_policy.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/picker/bible_reference_parser.dart';
import '../../../core/preferences/user_preferences.dart';
import '../application/chapter_player_notifier.dart';
import '../domain/audio_mode.dart';
import '../domain/bible_translation.dart';
import '../domain/chapter_info.dart';
import '../domain/passage_excerpt.dart';
import '../domain/scripture_topic.dart';
import 'widgets/chapter_picker_dialog.dart';
import 'widgets/feature_voting_sheet.dart';
import 'widgets/licensing_attribution_sheet.dart';
import 'widgets/offline_indicator.dart';
import 'widgets/passage_timing_feedback_bar.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/topic_tab_bar.dart';
import 'widgets/emoji_feedback_dialog.dart';
import 'about_selah_dialog.dart';
import '../../../core/feedback/feedback_service.dart';
import '../../../core/karaoke/timestamp_loader.dart';
import '../../../core/remote_config/remote_config_service.dart';

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
    final initialPassage = ref.read(chapterPlayerProvider).currentChapter.displayTitle ??
        ref.read(chapterPlayerProvider).currentChapter.reference;
    _searchController = TextEditingController(text: initialPassage);
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
      unawaited(_preferEsvThenExistingVerseQuery(raw));
      return;
    }

    _submitBookOrChapter(raw);
  }

  /// Verse and range searches use ESV when `ESV_API_KEY` is compiled in.
  /// Otherwise the existing narrator excerpt / bible-api.com path runs.
  Future<void> _preferEsvThenExistingVerseQuery(String raw) async {
    final played = await ref.read(chapterPlayerProvider.notifier).tryPlayEsvPassage(raw);
    if (!mounted) return;
    if (played) {
      ref.read(userPreferencesProvider).saveChapter(raw);
      setState(() {});
      return;
    }
    _submitColonQueryWithoutEsv(raw);
  }

  void _submitColonQueryWithoutEsv(String raw) {
    if (ref.read(esvPassagePolicyProvider).useEsvForPassages) {
      AppLogger.logEvent('request_single_verse', {'query': raw, 'esv_failed': true});
      return;
    }

    // Check for curated passages (1 Cor 13:4-7, Matt 11:28-30, Rom 8:31-39, Psalm 23)
    // If user typed a verse range (e.g. "col 1:17-20" or "matt 11:28-30")
      if (raw.contains('-') || raw.contains('–')) {
        final parsedList = BibleReferenceParser.getSuggestions(raw);
        if (parsedList.isNotEmpty) {
          final match = parsedList.first;
          final rangePattern = RegExp(r'(\d+)\s*[-–]\s*(\d+)');
          final m = rangePattern.firstMatch(raw);
          if (m != null) {
            final start = int.tryParse(m.group(1) ?? '') ?? 1;
            final end = int.tryParse(m.group(2) ?? '') ?? start;

            final hasTimestamps = TimestampLoaderService.hasCoverageForRange(
              bookCode: match.book.code,
              chapterNumber: match.chapter,
              startVerse: start,
              endVerse: end,
            );

            final displayTitle = '${match.book.name} ${match.chapter}:$start–$end';
            final customExcerpt = PassageExcerpt.customExcerpt(
              bookCode: match.book.code,
              chapterNumber: match.chapter,
              startVerse: start,
              endVerse: end,
              displayTitle: displayTitle,
            );

            // If timestamps exist for this chapter, play the custom excerpt immediately!
            if (hasTimestamps && customExcerpt != null) {
              ref.read(userPreferencesProvider).saveChapter(displayTitle);
              ref.read(chapterPlayerProvider.notifier).routeAndPlayChapter(
                bookCode: match.book.code,
                chapterNumber: match.chapter,
                bookName: match.book.name,
                excerpt: customExcerpt,
              );
              setState(() {});
              return;
            }

            // Chapter does not have WhisperX timestamps yet -> log demand and present choices
            AppLogger.logEvent('passage_alignment_requested', {
              'passage': raw,
              'book': match.book.code,
              'chapter': match.chapter,
              'start_verse': start,
              'end_verse': end,
              'translation': ref.read(chapterPlayerProvider).translation.code,
            });

            _showUnalignedPassageOptions(
              rawPassage: raw,
              bookCode: match.book.code,
              chapterNumber: match.chapter,
              bookName: match.book.name,
              startVerse: start,
              endVerse: end,
            );
            return;
          }
        }
      }

      final parsedList = BibleReferenceParser.getSuggestions(raw);
      if (parsedList.isNotEmpty) {
        final match = parsedList.first;
        final excerpt = PassageExcerpt.forChapter(match.book.code, match.chapter);
        if (excerpt != null) {
          final refStr = excerpt.displayTitle ?? '${match.book.name} ${match.chapter}:${excerpt.startVerse}-${excerpt.endVerse}';
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
      }

      AppLogger.logEvent('request_single_verse', {'query': raw});
      ref.read(userPreferencesProvider).saveChapter(raw);
      ref.read(chapterPlayerProvider.notifier).fetchAndPlaySingleVerse(raw, tryEsv: false);
      setState(() {});
  }

  void _submitBookOrChapter(String raw) {
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

  void _requestPassageFromDevs(String passage) async {
    final translation = ref.read(chapterPlayerProvider).translation.code;
    AppLogger.logEvent('passage_requested_from_devs', {
      'passage': passage,
      'translation': translation,
    });

    FeedbackService.requestPassageAlignment(
      passage: passage,
      translationCode: translation,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Requested "$passage" ($translation)! We\'ve notified the devs to align it with WhisperX. 🕊️'),
        backgroundColor: const Color(0xFF065F46),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showUnalignedPassageOptions({
    required String rawPassage,
    required String bookCode,
    required int chapterNumber,
    required String bookName,
    required int startVerse,
    required int endVerse,
  }) {
    final translation = ref.read(chapterPlayerProvider).translation.code;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Verse Timing Unaligned',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verse-level WhisperX timestamps for "$rawPassage" ($translation) are not aligned yet. How would you like to meditate?',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 24),
                ),
                title: Text('Play Full Chapter ($bookName $chapterNumber)', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Continuous human narrator audio in $translation', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(chapterPlayerProvider.notifier).routeAndPlayChapter(
                    bookCode: bookCode,
                    chapterNumber: chapterNumber,
                    bookName: bookName,
                  );
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded, color: Color(0xFFFBBF24), size: 22),
                ),
                title: const Text('Request Passage from Devs', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Notifies developers to prioritize WhisperX alignment for this passage', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _requestPassageFromDevs(rawPassage);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const FeatureVotingSheet(),
  );

  void _openSettingsModal() => showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1B4B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const SettingsBottomSheet(),
  );

  void _openSleepTimerModal(ChapterPlayerState playerState, ChapterPlayerNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = [null, 15, 30, 45, 60];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime_rounded, color: Color(0xFFFBBF24), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tranquil Sleep Timer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Audio gently fades out over 30 seconds before stopping peacefully.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((mins) {
                    final isSel = mins == playerState.sleepTimerMinutes;
                    final label = mins == null ? 'Off' : '$mins min';
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSel,
                      onSelected: (_) {
                        notifier.setSleepTimer(mins);
                        Navigator.of(ctx).pop();
                      },
                      selectedColor: const Color(0xFFFBBF24),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFF0F0E26),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTestedPassagesModal() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TestedPassagesBottomSheet(
        onSelectPassage: (query) {
          Navigator.of(ctx).pop();
          _handleSearchSubmit(query);
        },
        onRequestPassage: () {
          Navigator.of(ctx).pop();
          _showUnalignedPassageOptions(
            rawPassage: 'Custom Passage',
            bookCode: 'PSA',
            chapterNumber: 91,
            bookName: 'Psalm',
            startVerse: 1,
            endVerse: 4,
          );
        },
      ),
    );
  }

  void _openLicensingAttribution(BibleTranslation translation) =>
      LicensingAttributionSheet.show(context, translation: translation);

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);
    final userPrefs = ref.watch(userPreferencesProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);
    final showWip = ref.watch(workInProgressFeaturesProvider);
    final isFeatureVotingEnabled = remoteConfig.featureVotingEnabled || showWip;
    final policy = ref.watch(esvPassagePolicyProvider);

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
                    'Scripture Audio Meditation v0.4.1',
                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade200),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (playerState.isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: OfflineIndicator(
                isOffline: playerState.isOffline,
                isBundled: playerState.isBundledAsset,
              ),
            ),
          if (isFeatureVotingEnabled)
            IconButton(
              icon: const Icon(Icons.how_to_vote_rounded, color: Color(0xFFFBBF24)),
              tooltip: 'Feature Roadmap & Feedback',
              onPressed: _openFeatureVoting,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.indigoAccent),
            tooltip: 'About Selah',
            onPressed: () => AboutSelahDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: _openSettingsModal,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            tooltip: 'More Options',
            color: const Color(0xFF1E1B4B),
            onSelected: (value) {
              switch (value) {
                case 'feedback':
                  EmojiFeedbackDialog.show(
                    context,
                    currentChapter: playerState.currentChapter.displayTitle ??
                        playerState.currentChapter.reference,
                    translation: playerState.activeTranslation,
                  );
                  break;
                case 'about':
                  AboutSelahDialog.show(context);
                  break;
                case 'console':
                  setState(() => _showDebugLogs = !_showDebugLogs);
                  break;
                case 'logs':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TalkerScreen(talker: AppLogger.talker),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Color(0xFFFBBF24), size: 20),
                    SizedBox(width: 12),
                    Text('Prayer & Feedback', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.indigoAccent, size: 20),
                    SizedBox(width: 12),
                    Text('About Selah', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'console',
                child: Row(
                  children: [
                    Icon(
                      _showDebugLogs ? Icons.bug_report : Icons.bug_report_outlined,
                      color: _showDebugLogs ? Colors.greenAccent : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _showDebugLogs ? 'Hide Diagnostics' : 'Show Diagnostics',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logs',
                child: Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Talker Live Logs', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            56 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /* Optional Remote Config Announcement Banner */
              if (remoteConfig.announcementBannerText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, color: Color(0xFFFBBF24), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          remoteConfig.announcementBannerText,
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
              if (remoteConfig.enableTopicTabs)
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
                      final allChips = <({String label, ChapterInfo? chapter, bool isSaved})>[
                        ...kFeaturedChapters.map((c) => (
                              label: c.displayTitle ?? c.reference,
                              chapter: c as ChapterInfo?,
                              isSaved: savedSet.contains(c.reference.toLowerCase().trim()),
                            )),
                        ...savedList
                            .where((s) => !kFeaturedChapters.any((c) =>
                                c.reference.toLowerCase().trim() == s.toLowerCase().trim() ||
                                (c.displayTitle ?? '').toLowerCase().trim() == s.toLowerCase().trim()))
                            .map((s) => (
                                  label: s,
                                  chapter: null as ChapterInfo?,
                                  isSaved: true,
                                )),
                      ];

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: allChips.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == allChips.length) {
                            return _PresetChip(
                              label: '+ More (12)',
                              icon: Icons.library_books_rounded,
                              isSelected: false,
                              onTap: _openTestedPassagesModal,
                            );
                          }
                          final item = allChips[index];
                          final isSelected = playerState.currentChapter.reference.toLowerCase().trim() ==
                                  item.label.toLowerCase().trim() ||
                              (playerState.currentChapter.displayTitle ?? '').toLowerCase().trim() ==
                                  item.label.toLowerCase().trim();

                          return _PresetChip(
                            label: item.label,
                            isSelected: isSelected,
                            isBookmarked: item.isSaved,
                            onTap: () {
                              if (item.chapter != null) {
                                notifier.loadChapter(item.chapter!);
                              } else {
                                _handleSearchSubmit(item.label);
                              }
                            },
                          );
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
                        if (policy.showApiBibleTranslations)
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
                                  children: policy.selectableTranslations.map((tr) {
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
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0E26),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              'ESV',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
                    if (playerState.activeExcerpt != null ||
                        PassageExcerpt.forChapter(
                              playerState.currentChapter.bookCode,
                              playerState.currentChapter.chapterNumber,
                            ) !=
                            null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.spa_rounded, color: Color(0xFF34D399), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Curated Selah Meditation',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            playerState.activeTranslation == 'ESV'
                                ? 'English Standard Version (ESV) • Crossway'
                                : '${playerState.translation.fullName} (${playerState.activeTranslation}) • API.Bible${playerState.shuffleTranslations ? ' • 🔀 Shuffle Active' : ''}',
                            style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          key: const Key('info_attribution_icon'),
                          onTap: () => _openLicensingAttribution(playerState.translation),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: playerState.translation.isLicensed
                                  ? const Color(0xFFFBBF24)
                                  : Colors.indigo.shade200,
                            ),
                          ),
                        ),
                      ],
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
                      child: _KaraokeTextDisplay(playerState: playerState),
                    ),
                    const SizedBox(height: 10),

                    // Visible Attribution Badge & Licensing Modal Trigger
                    Center(
                      child: InkWell(
                        key: const Key('player_attribution_button'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openLicensingAttribution(playerState.translation),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                playerState.translation.isLicensed
                                    ? Icons.verified_user_outlined
                                    : Icons.public_rounded,
                                size: 13,
                                color: playerState.translation.isLicensed
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  playerState.translation.shortAttribution,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: playerState.translation.isLicensed
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: playerState.translation.isLicensed
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

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
                            child: _BreathCadenceIndicator(
                              isPausedInGap: playerState.isPausedInGap,
                              isPlaying: playerState.isPlaying,
                              gapSeconds: playerState.pauseGapSeconds,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            key: const Key('cycle_repetitions_chip'),
                            onTap: () {
                              final repsList = remoteConfig.parsedKnobOptions;
                              final currentIdx = repsList.indexOf(playerState.repetitions);
                              final nextReps = currentIdx >= 0
                                  ? repsList[(currentIdx + 1) % repsList.length]
                                  : repsList.first;
                              notifier.setRepetitions(nextReps);
                              AppLogger.logEvent('select_knob_value', {
                                'selected_repetitions': nextReps,
                                'knob_variant_group': repsList.length > 5 ? 'slider_1_to_25' : 'curated_1_3_7_inf',
                                'source': 'player_screen_loop_chip',
                              });
                              final label = nextReps == -1 ? 'Continuous ∞ Loop' : '${nextReps}x Repeat';
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Walking Repetitions: $label'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF4338CA),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat_rounded, color: Color(0xFFFBBF24), size: 14),
                                  const SizedBox(width: 4),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Play / Pause & Sleep / Speed Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Paced meditation speed button
                        GestureDetector(
                          onTap: () {
                            final current = playerState.playbackSpeed;
                            final next = current == 0.75
                                ? 0.85
                                : current == 0.85
                                    ? 1.0
                                    : current == 1.0
                                        ? 1.1
                                        : 0.75;
                            notifier.setPlaybackSpeed(next);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B4B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: playerState.playbackSpeed != 1.0
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.speed_rounded,
                                  size: 14,
                                  color: playerState.playbackSpeed != 1.0
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${playerState.playbackSpeed}x',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: playerState.playbackSpeed != 1.0
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Center Play / Pause
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

                        const SizedBox(width: 24),

                        // Sleep Timer button
                        GestureDetector(
                          onTap: () => _openSleepTimerModal(playerState, notifier),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B4B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: playerState.isSleepTimerActive
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  playerState.isSleepTimerActive
                                      ? Icons.bedtime_rounded
                                      : Icons.bedtime_outlined,
                                  size: 14,
                                  color: playerState.isSleepTimerActive
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white70,
                                ),
                                if (playerState.isSleepTimerActive) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${playerState.sleepTimerMinutes}m',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFBBF24),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /* Passage Timing & Quality Feedback Bar (Issue #95 / #119) */
              if (!ref.watch(esvPassagePolicyProvider).useEsvForPassages &&
                  playerState.activeTranslation != BibleTranslation.esv.code)
                PassageTimingFeedbackBar(
                  key: const Key('passage_timing_feedback_bar'),
                  passageTitle: playerState.currentChapter.displayTitle ?? playerState.currentChapter.reference,
                  translationCode: playerState.activeTranslation,
                  hasTimestamps: playerState.hasTimestamps,
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
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBookmarked;
  final IconData? icon;

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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 6),
              ] else if (isBookmarked) ...[
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

class _KaraokeTextDisplay extends StatefulWidget {
  const _KaraokeTextDisplay({required this.playerState});

  final dynamic playerState;

  @override
  State<_KaraokeTextDisplay> createState() => _KaraokeTextDisplayState();
}

class _KaraokeTextDisplayState extends State<_KaraokeTextDisplay> {
  final ScrollController _scrollController = ScrollController();
  int _lastHighlightStart = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _KaraokeTextDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final curStart = widget.playerState.highlightStart as int;
    final curChapter = widget.playerState.currentChapter;
    final oldChapter = oldWidget.playerState.currentChapter;

    // Reset scroll if chapter changed
    if (curChapter != oldChapter && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
      _lastHighlightStart = -1;
      return;
    }

    if (curStart != _lastHighlightStart && curStart > 0 && _scrollController.hasClients) {
      _lastHighlightStart = curStart;
      final text = widget.playerState.currentChapter.textContent as String;
      if (text.isNotEmpty) {
        final progress = (curStart / text.length).clamp(0.0, 1.0);
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          final targetOffset = (maxScroll * progress).clamp(0.0, maxScroll);
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.playerState.currentChapter.textContent as String;
    Widget content;

    if (widget.playerState.highlightEnd > widget.playerState.highlightStart &&
        widget.playerState.highlightEnd <= text.length) {
      final before = text.substring(0, widget.playerState.highlightStart);
      final word = text.substring(widget.playerState.highlightStart, widget.playerState.highlightEnd);
      final after = text.substring(widget.playerState.highlightEnd);

      content = RichText(
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
    } else {
      content = Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.newsreader(
          fontSize: 15,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.87),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: content,
    );
  }
}

class _TestedPassagesBottomSheet extends ConsumerStatefulWidget {
  const _TestedPassagesBottomSheet({
    required this.onSelectPassage,
    required this.onRequestPassage,
  });

  final void Function(String query) onSelectPassage;
  final VoidCallback onRequestPassage;

  @override
  ConsumerState<_TestedPassagesBottomSheet> createState() => _TestedPassagesBottomSheetState();
}

class _TestedPassagesBottomSheetState extends ConsumerState<_TestedPassagesBottomSheet> {
  CatalogTier? _overrideTier;

  @override
  Widget build(BuildContext context) {
    final activeTier = _overrideTier ?? ref.watch(catalogTierProvider);
    final passages = activeTier == CatalogTier.curated12
        ? kCurated12Excerpts
        : activeTier == CatalogTier.biblical40
            ? kBiblical40Excerpts
            : kSoftLaunch77Excerpts;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          maintainBottomViewPadding: true,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
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
                    const Icon(Icons.verified_rounded, color: Color(0xFFFBBF24), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Scripture Meditation Catalog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  '${passages.length} contemplative passages with calibrated verse boundaries & reflective pacing.',
                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('🌿 Curated 12 (${kCurated12Excerpts.length})'),
                        selected: activeTier == CatalogTier.curated12,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F0E26),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: activeTier == CatalogTier.curated12 ? Colors.white : Colors.white60,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _overrideTier = CatalogTier.curated12);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('📜 Biblical 40 (${kBiblical40Excerpts.length})'),
                        selected: activeTier == CatalogTier.biblical40,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F0E26),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: activeTier == CatalogTier.biblical40 ? Colors.white : Colors.white60,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _overrideTier = CatalogTier.biblical40);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('🕊️ The 77 (${kSoftLaunch77Excerpts.length})'),
                        selected: activeTier == CatalogTier.softLaunch77 || activeTier == CatalogTier.allPassages,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F0E26),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (activeTier == CatalogTier.softLaunch77 || activeTier == CatalogTier.allPassages)
                              ? Colors.white
                              : Colors.white60,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _overrideTier = CatalogTier.softLaunch77);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: passages.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = passages[index];
                      final titleStr = item.displayTitle ?? '${item.bookCode} ${item.chapterNumber}:${item.startVerse}–${item.endVerse}';
                      final descStr = item.theme ?? 'Curated Selah Meditation';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        title: Row(
                          children: [
                            Text(
                              titleStr,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: index < 12
                                    ? const Color(0xFF064E3B).withValues(alpha: 0.8)
                                    : index < 40
                                        ? const Color(0xFF312E81).withValues(alpha: 0.8)
                                        : const Color(0xFF701A75).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                index < 12
                                    ? '🌿 Curated'
                                    : index < 40
                                        ? '📜 Biblical 40'
                                        : '🕊️ The 77',
                                style: TextStyle(
                                  color: index < 12
                                      ? const Color(0xFF34D399)
                                      : index < 40
                                          ? const Color(0xFFA5B4FC)
                                          : const Color(0xFFF472B6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          descStr,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF6366F1), size: 28),
                        onTap: () => widget.onSelectPassage(titleStr),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, color: Color(0xFFFBBF24)),
                    label: const Text('Request Another Passage', style: TextStyle(color: Color(0xFFFBBF24))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFBBF24)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.onRequestPassage,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BreathCadenceIndicator extends StatefulWidget {
  const _BreathCadenceIndicator({
    required this.isPausedInGap,
    required this.isPlaying,
    required this.gapSeconds,
  });

  final bool isPausedInGap;
  final bool isPlaying;
  final int gapSeconds;

  @override
  State<_BreathCadenceIndicator> createState() => _BreathCadenceIndicatorState();
}

class _BreathCadenceIndicatorState extends State<_BreathCadenceIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    if (widget.isPausedInGap) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BreathCadenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPausedInGap && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPausedInGap && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPausedInGap) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isExhaling = _controller.status == AnimationStatus.reverse;
          final breathLabel = isExhaling ? 'Exhale stillness...' : 'Inhale peace...';
          return Row(
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFBBF24).withValues(alpha: _glowAnimation.value.clamp(0.0, 1.0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: (0.5 * _glowAnimation.value).clamp(0.0, 1.0)),
                        blurRadius: 8 * _scaleAnimation.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🌿 $breathLabel (${widget.gapSeconds}s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFDE68A),
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isPlaying ? Colors.greenAccent : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.isPlaying ? 'Meditating...' : 'Ready',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


