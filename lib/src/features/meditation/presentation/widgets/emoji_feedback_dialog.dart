import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/remote_config/remote_config_service.dart';

/// Streamlined Peaceful App Feedback Dialog.
///
/// Provides a clear, peaceful way for meditators to share encouragement,
/// feature suggestions, or report issues without developer jargon or friction.
class EmojiFeedbackDialog extends ConsumerStatefulWidget {
  const EmojiFeedbackDialog({
    super.key,
    this.currentChapter,
    this.translation,
  });

  final String? currentChapter;
  final String? translation;

  static Future<void> show(
    BuildContext context, {
    String? currentChapter,
    String? translation,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => EmojiFeedbackDialog(
        currentChapter: currentChapter,
        translation: translation,
      ),
    );
  }

  @override
  ConsumerState<EmojiFeedbackDialog> createState() => _EmojiFeedbackDialogState();
}

typedef FeedbackDialog = EmojiFeedbackDialog;

class _EmojiFeedbackDialogState extends ConsumerState<EmojiFeedbackDialog> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedFace = 'happy'; // 'happy', 'neutral', 'sad'
  int _selectedRating = 5;
  String _selectedEmoji = '😊';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<Map<String, dynamic>> _sentimentOptions = [
    {
      'face': 'happy',
      'emoji': '😊',
      'label': 'Loving it!',
      'hint': 'What are you enjoying most about Selah? (optional reflection)',
      'buttonLabel': 'Send Blessing & Praise',
      'defaultRating': 5,
    },
    {
      'face': 'neutral',
      'emoji': '💡',
      'label': 'Suggestion',
      'hint': 'What features or passages would help your meditation?',
      'buttonLabel': 'Send Suggestion',
      'defaultRating': 4,
    },
    {
      'face': 'sad',
      'emoji': '🛠️',
      'label': 'Needs work',
      'hint': 'What felt frustrating or broken in the app or audio?',
      'buttonLabel': 'Send Feedback',
      'defaultRating': 2,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSelectSentiment(Map<String, dynamic> opt) {
    setState(() {
      _selectedFace = opt['face'] as String;
      _selectedEmoji = opt['emoji'] as String;
      _selectedRating = opt['defaultRating'] as int;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    String? ghToken;
    try {
      ghToken = ref.read(remoteConfigProvider).githubFeedbackToken;
    } catch (_) {
      ghToken = null;
    }
    await FeedbackService.submitFeedback(
      rating: _selectedRating,
      emoji: _selectedEmoji,
      face: _selectedFace,
      message: _commentController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      currentChapter: widget.currentChapter,
      translation: widget.translation,
      githubToken: ghToken,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    if (_isSubmitted) {
      return Dialog(
        backgroundColor: const Color(0xFF161536),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: EdgeInsets.fromLTRB(
          20,
          24 + mediaPadding.top,
          20,
          24 + mediaPadding.bottom,
        ),
        child: SafeArea(
          maintainBottomViewPadding: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Thank You!',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your note has been received with care. May God bless your time in Scripture and meditation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('return_to_meditation_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Meditation', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final activeOpt = _sentimentOptions.firstWhere(
      (opt) => opt['face'] == _selectedFace,
      orElse: () => _sentimentOptions.first,
    );
    final hintText = activeOpt['hint'] as String;
    final buttonLabel = activeOpt['buttonLabel'] as String;

    return Dialog(
      backgroundColor: const Color(0xFF161536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade700.withValues(alpha: 0.5)),
      ),
      insetPadding: EdgeInsets.fromLTRB(
        20,
        24 + mediaPadding.top,
        20,
        24 + mediaPadding.bottom,
      ),
      child: SafeArea(
        maintainBottomViewPadding: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Color(0xFFFBBF24), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prayer & Feedback',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Share an encouraging word or suggestion',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // Sentiment Selector
                  const Text(
                    'HOW IS YOUR MEDITATION EXPERIENCE?',
                    style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _sentimentOptions.map((opt) {
                      final faceKey = opt['face'] as String;
                      final isSel = _selectedFace == faceKey;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            key: Key('face_option_$faceKey'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _onSelectSentiment(opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (faceKey == 'happy'
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : (faceKey == 'neutral'
                                            ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.2)))
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel
                                      ? (faceKey == 'happy'
                                          ? const Color(0xFF10B981)
                                          : (faceKey == 'neutral'
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFF87171)))
                                      : Colors.white12,
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(opt['emoji'] as String, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(height: 6),
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSel ? Colors.white : Colors.white60,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reflection / Feedback Note
                  TextField(
                    key: const Key('feedback_comment_field'),
                    controller: _commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optional Email for follow up
                  TextField(
                    key: const Key('feedback_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Your email (optional, for follow-up reply)',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Submission Button
                  ElevatedButton(
                    key: const Key('submit_feedback_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFace == 'happy'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            buttonLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 8),

                  // Optional Screenshot Drawing
                  TextButton.icon(
                    key: const Key('screenshot_feedback_button'),
                    icon: const Icon(Icons.draw_rounded, size: 16, color: Color(0xFFFBBF24)),
                    label: const Text(
                      'Draw on Screenshot & Send',
                      style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      final rating = _selectedRating;
                      final face = _selectedFace;
                      final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null;
                      String? ghToken;
                      try {
                        ghToken = ref.read(remoteConfigProvider).githubFeedbackToken;
                      } catch (_) {
                        ghToken = null;
                      }
                      Navigator.of(context).pop();
                      BetterFeedback.of(context).show((UserFeedback feedback) async {
                        await FeedbackService.submitBetterFeedback(
                          feedback: feedback,
                          rating: rating,
                          face: face,
                          email: email,
                          githubToken: ghToken,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
