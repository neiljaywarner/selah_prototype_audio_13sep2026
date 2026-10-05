import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final Map<String, dynamic> _defaults = {
    'default_translation': 'BSB',
    'default_repetitions': 3,
    'default_pause_gap': 4,
    'feedback_board_enabled': true,
    'enable_topic_tabs': false, // Hidden until v0.4 passage playlists
    'karaoke_experimental_enabled': false,
  };

  Map<String, dynamic> _currentValues = {};

  Future<void> init() async {
    _currentValues = Map.from(_defaults);
    debugPrint('⚙️ [REMOTE CONFIG]: Initialized with defaults: $_currentValues');
  }

  String getString(String key) => (_currentValues[key] ?? _defaults[key] ?? '').toString();
  int getInt(String key) => int.tryParse(_currentValues[key]?.toString() ?? '') ?? (_defaults[key] as int? ?? 0);
  bool getBool(String key) => (_currentValues[key] ?? _defaults[key]) == true;
}
