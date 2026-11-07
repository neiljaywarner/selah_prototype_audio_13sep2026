import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';

/// Usage: I share {'1 Cor 13:4-7'} from My Passages
Future<void> iShareFromMyPassages(WidgetTester tester, String reference) async {
  final parsed = PassageShareLink.tryParse(reference);
  expect(parsed, isNotNull);
  final open = find.byKey(const Key('open_my_passages'));
  expect(open, findsOneWidget);
  await tester.ensureVisible(open);
  await tester.tap(open);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.byKey(const Key('my_passages_sheet')), findsOneWidget);
  final share = find.byKey(Key('share_my_passage_${parsed!.canonical}'));
  expect(share, findsOneWidget);
  await tester.tap(share);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
