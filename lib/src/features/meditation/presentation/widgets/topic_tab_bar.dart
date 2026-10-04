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
              return ChoiceChip(
                label: Text('${topic.iconEmoji} ${topic.title}'),
                selected: isSelected,
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1E1B4B),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) => onTopicSelected(topic),
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

              return ActionChip(
                label: Text(chapter.reference),
                backgroundColor: isCurrent
                    ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                    : const Color(0xFF0F0E26),
                side: BorderSide(
                  color: isCurrent ? const Color(0xFFFBBF24) : Colors.white12,
                ),
                labelStyle: TextStyle(
                  color: isCurrent ? const Color(0xFFFBBF24) : Colors.white70,
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                onPressed: () => onChapterSelected(chapter),
              );
            },
          ),
        ),
      ],
    );
  }
}
