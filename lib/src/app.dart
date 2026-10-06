import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/meditation/presentation/chapter_player_screen.dart';

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Selah - Scripture Meditation',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.dark,
    darkTheme: AppTheme.darkTheme,
    home: const ChapterPlayerScreen(),
  );
}
