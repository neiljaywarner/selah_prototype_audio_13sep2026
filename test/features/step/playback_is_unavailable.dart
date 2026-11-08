import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: playback is unavailable
Future<void> playbackIsUnavailable(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  final node = tester.getSemantics(find.byKey(const Key('play_passage_button')));
  expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
  expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);
  handle.dispose();
}
