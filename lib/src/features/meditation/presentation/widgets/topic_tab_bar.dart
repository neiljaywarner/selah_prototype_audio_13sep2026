import 'package:flutter/material.dart';
import '../../domain/chapter_info.dart';
import '../../domain/scripture_topic.dart';

class TopicTabBar extends StatelessWidget {
  final List<ScriptureTopic> topics;
  final ScriptureTopic selectedTopic;
  final void Function(ScriptureTopic topic) onTopicSelected;
  final void Function(ChapterInfo chapter) onChapterSelected;
  final String activeReference;

  const TopicTabBar({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.onTopicSelected,
    required this.onChapterSelected,
    required this.activeReference,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Selector Chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: topics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final topic = topics[index];
              final isSelected = selectedTopic.id == topic.id;
              return _TopicSelectorChip(
                topic: topic,
                isSelected: isSelected,
                onTap: () => onTopicSelected(topic),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Chapter Chips for Selected Topic
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedTopic.chapters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chapter = selectedTopic.chapters[index];
              final isCurrent = chapter.reference.toUpperCase() == activeReference.toUpperCase();

              return _TopicChapterChip(
                chapter: chapter,
                isCurrent: isCurrent,
                onTap: () => onChapterSelected(chapter),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopicSelectorChip extends StatelessWidget {
  const _TopicSelectorChip({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  final ScriptureTopic topic;
  final bool isSelected;
  final VoidCallback onTap;

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
          child: Text(
            '${topic.iconEmoji} ${topic.title}',
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicChapterChip extends StatelessWidget {
  const _TopicChapterChip({
    required this.chapter,
    required this.isCurrent,
    required this.onTap,
  });

  final ChapterInfo chapter;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                : const Color(0xFF0F0E26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent ? const Color(0xFFFBBF24) : Colors.white24,
              width: 1.0,
            ),
          ),
          child: Text(
            chapter.reference,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: isCurrent ? const Color(0xFFFBBF24) : const Color(0xFFF8FAFC),
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
