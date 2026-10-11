import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/chapter_picker_dialog.dart';

void main() {
  testWidgets('ChapterPickerDialog auto-switches to numeric keyboard on "John "', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? selectedBookCode;
    int? selectedChapterNumber;
    String? selectedBookName;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterPickerDialog(
            onChapterSelected: (code, ch, name) {
              selectedBookCode = code;
              selectedChapterNumber = ch;
              selectedBookName = name;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: Text input type is TextInputType.text
    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);

    TextField textField = tester.widget<TextField>(searchFieldFinder);
    expect(textField.keyboardType, equals(TextInputType.text));

    // 2. Type "John " (book name followed by space)
    await tester.enterText(searchFieldFinder, 'John ');
    await tester.pumpAndSettle();

    // 3. Verify it identified John and switched keyboard to TextInputType.number
    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, equals(TextInputType.number));
    expect(find.textContaining('John selected • Numeric keypad active'), findsOneWidget);

    // 4. Type chapter 14 ("John 14")
    await tester.enterText(searchFieldFinder, 'John 14');
    await tester.pumpAndSettle();

    // Chapter 14 button at bottom
    expect(find.text('Play John 14'), findsOneWidget);

    // 5. Tap Play John 14
    await tester.tap(find.text('Play John 14'));
    await tester.pumpAndSettle();

    expect(selectedBookCode, equals('JHN'));
    expect(selectedChapterNumber, equals(14));
    expect(selectedBookName, equals('John'));
  });

  testWidgets('ChapterPickerDialog reverts to text keyboard when backspacing to incomplete prefix', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterPickerDialog(
            onChapterSelected: (_, _, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchFieldFinder = find.byType(TextField);

    // Type "Rom "
    await tester.enterText(searchFieldFinder, 'Rom ');
    await tester.pumpAndSettle();

    TextField textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, equals(TextInputType.number));

    // Backspace to "Ro"
    await tester.enterText(searchFieldFinder, 'Ro');
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, equals(TextInputType.text));
    expect(find.textContaining('Numeric keypad active'), findsNothing);
  });
}
