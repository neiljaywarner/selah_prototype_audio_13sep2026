import 'package:flutter_test/flutter_test.dart';

/// Usage: the attribution includes {'Barry Hays'}
Future<void> theAttributionIncludes(WidgetTester tester, String wording) async {
  expect(find.textContaining(wording), findsWidgets);
}
