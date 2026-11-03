import 'package:flutter/material.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/popular_passage.dart';
import '../../application/popular_passages_service.dart';

class PopularPassagesBottomSheet extends StatefulWidget {
  final ValueChanged<String> onSelectPassage;
  final PopularPassagesService? service;

  const PopularPassagesBottomSheet({
    super.key,
    required this.onSelectPassage,
    this.service,
  });

  @override
  State<PopularPassagesBottomSheet> createState() => _PopularPassagesBottomSheetState();
}

class _PopularPassagesBottomSheetState extends State<PopularPassagesBottomSheet> {
  PopularTimeframe _timeframe = PopularTimeframe.thisWeek;
  PopularSortBy _sortBy = PopularSortBy.byMeditators;

  late final PopularPassagesService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PopularPassagesService();
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = (n % 1000).toString().padLeft(3, '0');
      return '$thousands,$remainder';
    }
    return n.toString();
  }

  String _timeframeLabel(PopularTimeframe tf) {
    switch (tf) {
      case PopularTimeframe.thisWeek:
        return 'This Week';
      case PopularTimeframe.thisMonth:
        return 'This Month';
      case PopularTimeframe.allTime:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final passages = _service.getPopularPassages(
      timeframe: _timeframe,
      sortBy: _sortBy,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1B4B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Popular Passages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Scriptures where fellow believers have spent the most time resting and looping in contemplation.',
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
              ),
            ),
            const SizedBox(height: 12),

            // Filter & Sort Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Timeframe ChoiceChips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PopularTimeframe.values.map((tf) {
                          final isSelected = _timeframe == tf;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(_timeframeLabel(tf)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF6366F1),
                              backgroundColor: const Color(0xFF0F0E26),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                              visualDensity: VisualDensity.compact,
                              onSelected: (val) {
                                if (val) setState(() => _timeframe = tf);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Sort Order Toggle
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _sortBy = _sortBy == PopularSortBy.byMeditators
                            ? PopularSortBy.byLoops
                            : PopularSortBy.byMeditators;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortBy == PopularSortBy.byMeditators
                                ? Icons.people_outline_rounded
                                : Icons.repeat_rounded,
                            size: 15,
                            color: const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _sortBy == PopularSortBy.byMeditators ? 'Meditators' : 'Loops',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            const Divider(color: Colors.white10, height: 1),

            // Passages List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: passages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final passage = passages[index];
                  final meditators = passage.getMeditators(_timeframe);
                  final loops = passage.getLoops(_timeframe);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        AppLogger.logEvent('select_popular_passage', {
                          'reference': passage.reference,
                          'timeframe': _timeframe.name,
                          'sort_by': _sortBy.name,
                          'meditators': meditators,
                          'loops': loops,
                        });
                        Navigator.of(context).pop();
                        widget.onSelectPassage(passage.reference);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0E26).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Passage Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        passage.reference,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          passage.theme,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo.shade100,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    passage.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_formatNumber(meditators)} meditators • ${_formatNumber(loops)} loops',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.indigo.shade200,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Play action icon
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFF6366F1),
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
