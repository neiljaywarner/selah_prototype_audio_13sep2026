import 'package:flutter/material.dart';
import '../../../../core/feedback/feedback_service.dart';

/// A calm, non-intrusive in-player feedback widget allowing meditators to
/// give thumbs up/down on passage audio and timing boundaries (Issue #95 / #119).
class PassageTimingFeedbackBar extends StatefulWidget {
  final String passageTitle;
  final String translationCode;
  final String? githubToken;
  final bool hasTimestamps;

  const PassageTimingFeedbackBar({
    super.key,
    required this.passageTitle,
    required this.translationCode,
    this.githubToken,
    this.hasTimestamps = true,
  });

  @override
  State<PassageTimingFeedbackBar> createState() => _PassageTimingFeedbackBarState();
}

class _PassageTimingFeedbackBarState extends State<PassageTimingFeedbackBar> {
  bool _submittedThumbsUp = false;
  bool _requestedFromDevs = false;

  void _handleThumbsUp() async {
    setState(() => _submittedThumbsUp = true);
    await FeedbackService.submitAudioTimingFeedback(
      passageTitle: widget.passageTitle,
      translationCode: widget.translationCode,
      isThumbsUp: true,
      githubToken: widget.githubToken,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Glad the audio was peaceful. 🕊️'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF065F46),
      ),
    );
  }

  void _handleRequestFromDevs() async {
    setState(() => _requestedFromDevs = true);
    await FeedbackService.requestPassageAlignment(
      passage: widget.passageTitle,
      translationCode: widget.translationCode,
      githubToken: widget.githubToken,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Requested ${widget.passageTitle}! We\'ve notified the devs to align it with WhisperX. 🕊️'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF065F46),
      ),
    );
  }

  void _handleThumbsDown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TimingCalibrationSheet(
        passageTitle: widget.passageTitle,
        translationCode: widget.translationCode,
        githubToken: widget.githubToken,
        timestampsMissingDefault: !widget.hasTimestamps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: widget.hasTimestamps
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.graphic_eq,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Audio & timing peaceful?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                if (_submittedThumbsUp) ...[
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Saved 🕊️',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    color: Colors.white.withValues(alpha: 0.7),
                    tooltip: 'Audio and timing are good',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _handleThumbsUp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_outlined, size: 16),
                    color: Colors.white.withValues(alpha: 0.7),
                    tooltip: 'Report audio timing or clipping issue',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _handleThumbsDown,
                  ),
                ],
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: Colors.amberAccent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Verse timing unaligned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_requestedFromDevs) ...[
                  const Icon(Icons.check_circle, size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Requested 🕊️',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ] else ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _handleRequestFromDevs,
                    child: const Text(
                      'Request from devs',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.tune, size: 16),
                  color: Colors.white.withValues(alpha: 0.7),
                  tooltip: 'Report audio or timing issue',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _handleThumbsDown,
                ),
              ],
            ),
    );
  }
}

class _TimingCalibrationSheet extends StatefulWidget {
  final String passageTitle;
  final String translationCode;
  final String? githubToken;
  final bool timestampsMissingDefault;

  const _TimingCalibrationSheet({
    required this.passageTitle,
    required this.translationCode,
    this.githubToken,
    this.timestampsMissingDefault = false,
  });

  @override
  State<_TimingCalibrationSheet> createState() => _TimingCalibrationSheetState();
}

class _TimingCalibrationSheetState extends State<_TimingCalibrationSheet> {
  late bool _startedWrong;
  bool _endedWrong = false;
  bool _audioGlitch = false;
  late bool _timestampsMissing;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _timestampsMissing = widget.timestampsMissingDefault;
    _startedWrong = !widget.timestampsMissingDefault;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isSubmitting = true);
    await FeedbackService.submitAudioTimingFeedback(
      passageTitle: widget.passageTitle,
      translationCode: widget.translationCode,
      isThumbsUp: false,
      startedWrong: _startedWrong,
      endedWrong: _endedWrong,
      audioGlitch: _audioGlitch,
      timestampsMissing: _timestampsMissing,
      userNote: _noteController.text,
      githubToken: widget.githubToken,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted. We will recalibrate this passage! 🕊️'),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF4C1D95),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFFA78BFA), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio & Timing Calibration',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.passageTitle} (${widget.translationCode})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What needs adjustment?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _startedWrong,
              activeColor: const Color(0xFF8B5CF6),
              title: const Text(
                'Started too early or cut into words',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _startedWrong = val ?? false),
            ),
            CheckboxListTile(
              value: _endedWrong,
              activeColor: const Color(0xFF8B5CF6),
              title: const Text(
                'Cut off before verse finished',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _endedWrong = val ?? false),
            ),
            CheckboxListTile(
              value: _audioGlitch,
              activeColor: const Color(0xFF8B5CF6),
              title: const Text(
                'Audio glitch or distortion',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _audioGlitch = val ?? false),
            ),
            CheckboxListTile(
              value: _timestampsMissing,
              activeColor: const Color(0xFF8B5CF6),
              title: const Text(
                'Verse timestamps unaligned / request WhisperX',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _timestampsMissing = val ?? false),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Optional note (e.g., words clipped in verse 2)...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Send Calibration Report',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
