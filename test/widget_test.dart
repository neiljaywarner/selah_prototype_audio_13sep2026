import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  testWidgets('SelahApp smoke test builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SelahApp(),
      ),
    );

    expect(find.text('SELAH'), findsOneWidget);
    expect(find.text('Scripture Audio Meditation'), findsOneWidget);
  });
}
