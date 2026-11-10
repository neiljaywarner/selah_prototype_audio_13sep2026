import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/scripture_topic.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/topic_tab_bar.dart';

void main() {
  testWidgets('Choosing Peace shows a peace passage', (tester) async {
    var selected = kDefaultMeditationTopics.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TopicTabBar(
                topics: kDefaultMeditationTopics,
                selectedTopic: selected,
                activeReference: selected.chapters.first.reference,
                onTopicSelected: (topic) => setState(() => selected = topic),
                onChapterSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('Featured'), findsOneWidget);
    expect(selected.title, 'Featured');

    await tester.tap(find.textContaining('Peace'));
    await tester.pumpAndSettle();

    expect(selected.title, 'Peace');
    expect(find.text('Philippians 4'), findsOneWidget);
    expect(find.text('John 14'), findsOneWidget);
  });
}
