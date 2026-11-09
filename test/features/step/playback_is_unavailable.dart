import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: playback is unavailable
Future<void> playbackIsUnavailable(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  final handle = tester.ensureSemantics();
  final node = tester.getSemantics(play);
  expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
  expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);
  handle.dispose();

  final gesture = tester.widget<GestureDetector>(play);
  expect(gesture.onTap, isNull);
  final circle = tester.widget<Container>(
    find.descendant(of: play, matching: find.byType(Container)),
  );
  final decoration = circle.decoration! as BoxDecoration;
  expect(decoration.gradient, isNull);
  expect(decoration.boxShadow, isNull);
  expect(decoration.color, const Color(0xFF3A3658));
  final icon = tester.widget<Icon>(find.descendant(of: play, matching: find.byType(Icon)));
  expect(icon.color, Colors.white38);
}
