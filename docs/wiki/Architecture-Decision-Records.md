# Architecture Decision Records (ADR Index)

This wiki page indexes key architectural decisions for Selah Scripture Audio Meditation.

## ADR Summary Table

| ADR ID | Decision Title | Status | Date | Summary |
| :--- | :--- | :--- | :--- | :--- |
| **ADR-0001** | State Management with Riverpod Notifiers | Accepted | 2026-09 | Use Flutter Riverpod StateNotifier for immutable player state, eliminating setState spaghetti. |
| **ADR-0002** | Client-Side Audio Stream Clipping via WhisperX | Accepted | 2026-10 | Clip whole-chapter API.Bible streams using precomputed forced-alignment timestamps in Just_audio, avoiding expensive backend FFmpeg servers. |

---

## Detailed ADR Summaries

### ADR-0002: Client-Side Audio Stream Clipping via WhisperX Timestamps
- **Context**: API.Bible provides only whole-chapter audio files.
- **Decision**: Forced-align verse timestamps using WhisperX offline. At runtime, pass `start` and `end` millisecond boundaries to `_audioPlayer.setClip(...)`.
- **Outcome**: $0 backend cost, zero initial transcoding wait time, precise looping and karaoke synchronization.
