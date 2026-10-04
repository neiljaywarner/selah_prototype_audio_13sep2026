enum AudioMode {
  narrator,
  tts,
}

extension AudioModeX on AudioMode {
  String get label {
    switch (this) {
      case AudioMode.narrator:
        return '🎙️ Human Narrator';
      case AudioMode.tts:
        return '🗣️ Peaceful TTS';
    }
  }

  bool get isNarrator => this == AudioMode.narrator;
  bool get isTts => this == AudioMode.tts;
}
