import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/remote_config/remote_config_service.dart';

/// 3-Face App Feedback Dialog (Happy 😊, Neutral 😐, Sad 😞)
///
/// Funnel logic:
/// - 😊 Happy: Encourages rating 4–5 stars and leaving praise/blessing.
/// - 😐 Neutral: Funnels directly to private feedback on what can be improved.
/// - 😞 Sad: Funnels directly to private bug/frustration feedback routed to Neil.
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

class _EmojiFeedbackDialogState extends ConsumerState<EmojiFeedbackDialog> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedFace = 'happy'; // 'happy', 'neutral', 'sad'
  int _selectedRating = 5;
  String _selectedEmoji = '😊';
  String _selectedLabel = 'Loving it!';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<Map<String, dynamic>> _faceOptions = [
    {
      'face': 'happy',
      'emoji': '😊',
      'label': 'Loving it!',
      'defaultRating': 5,
    },
    {
      'face': 'neutral',
      'emoji': '😐',
      'label': 'It is okay',
      'defaultRating': 3,
    },
    {
      'face': 'sad',
      'emoji': '😞',
      'label': 'Needs work',
      'defaultRating': 1,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSelectFace(Map<String, dynamic> opt) {
    setState(() {
      _selectedFace = opt['face'] as String;
      _selectedEmoji = opt['emoji'] as String;
      _selectedLabel = opt['label'] as String;
      _selectedRating = opt['defaultRating'] as int;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    await FeedbackService.submitFeedback(
      rating: _selectedRating,
      emoji: _selectedEmoji,
      face: _selectedFace,
      message: _commentController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      currentChapter: widget.currentChapter,
      translation: widget.translation,
    );

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  void _handleEmailDirect() {
    final comment = _commentController.text.trim();
    final body = 'Face: $_selectedEmoji ($_selectedLabel) • Rating: $_selectedRating/5\n'
        'Passage: ${widget.currentChapter ?? "N/A"}\n'
        'Translation: ${widget.translation ?? "N/A"}\n\n'
        'Private Reflection / Feedback:\n$comment\n\n'
        'Private Triage Hub: https://github.com/${FeedbackService.privateGitHubRepo}';

    Clipboard.setData(ClipboardData(
      text: 'To: ${FeedbackService.defaultFeedbackEmail}\nSubject: [Selah App Feedback] $_selectedEmoji $_selectedLabel\n\n$body',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Private email copied to clipboard! You can send directly to neilwarner+selah@gmail.com',
        ),
        backgroundColor: Color(0xFF4338CA),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Dialog(
        backgroundColor: const Color(0xFF161536),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_selectedFace == 'happy' ? Colors.greenAccent : const Color(0xFFFBBF24))
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(_selectedEmoji, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFace == 'happy' ? 'Praise God! Thank You!' : 'Thank You for Your Feedback!',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFace == 'happy'
                    ? 'Your encouragement blesses our team and helps shape Selah for believers worldwide.'
                    : 'Your honest feedback is safely recorded in our private triage inbox. Neil reviews every note personally to make Selah better.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to Meditation'),
              ),
            ],
          ),
        ),
      );
    }

    final isHappy = _selectedFace == 'happy';

    return Dialog(
      backgroundColor: const Color(0xFF161536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade700.withValues(alpha: 0.5)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      child: const Icon(Icons.rate_review_rounded, color: Color(0xFFFBBF24), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How do you like Selah?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Help us improve your audio meditation',
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
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // 3-Face Reaction Row
                const Text(
                  'SELECT YOUR APP EXPERIENCE',
                  style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _faceOptions.map((opt) {
                    final faceKey = opt['face'] as String;
                    final isSel = _selectedFace == faceKey;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          key: Key('face_option_$faceKey'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _onSelectFace(opt),
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
                                Text(opt['emoji'] as String, style: const TextStyle(fontSize: 28)),
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
                const SizedBox(height: 18),

                // Dynamic Funnel Content
                if (isHappy) ...[
                  // HAPPY FUNNEL: Encourage 4 or 5 stars and public praise
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Glad you love it! Would you rate Selah 4 or 5 stars?',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [4, 5].map((star) {
                      final isStarSel = _selectedRating == star;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          key: Key('rating_star_$star'),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$star ', style: TextStyle(color: isStarSel ? Colors.black : Colors.white)),
                              Icon(Icons.star_rounded, size: 16, color: isStarSel ? Colors.black : const Color(0xFFFBBF24)),
                            ],
                          ),
                          selected: isStarSel,
                          selectedColor: const Color(0xFFFBBF24),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          onSelected: (_) => setState(() => _selectedRating = star),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // NEUTRAL / SAD FUNNEL: Private Feedback Funnel
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedFace == 'sad' ? Icons.healing_rounded : Icons.lock_outline_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFace == 'sad'
                                ? '🔒 Private Pre-Triage: Tell Neil what felt frustrating or broken.'
                                : '🔒 Private Pre-Triage: Help us make Selah more peaceful for you.',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Comment input
                TextField(
                  key: const Key('feedback_comment_field'),
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isHappy
                        ? 'What do you love most about Selah? (optional reflection)'
                        : (_selectedFace == 'sad'
                            ? 'What went wrong or felt broken? (private note to devs)'
                            : 'What could we improve or add? (private note to devs)'),
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

                // Email input
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

                // Action Buttons
                ElevatedButton(
                  key: const Key('submit_feedback_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHappy ? const Color(0xFF10B981) : const Color(0xFF6366F1),
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
                          isHappy
                              ? 'Submit $_selectedRating-Star Rating & Praise'
                              : 'Submit Private Feedback',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 8),

                // Secondary direct action for private funnel
                OutlinedButton.icon(
                  key: const Key('email_direct_button'),
                  icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: Colors.indigoAccent),
                  label: Text(
                    isHappy ? 'Share Review via Email' : 'Email Neil Directly (Private)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _handleEmailDirect,
                ),
                const SizedBox(height: 6),

                // Screenshot annotation via BetterFeedback
                TextButton.icon(
                  key: const Key('screenshot_feedback_button'),
                  icon: const Icon(Icons.draw_rounded, size: 15, color: Color(0xFFFBBF24)),
                  label: const Text(
                    'Draw on Screenshot & Send',
                    style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final rating = _selectedRating;
                    final face = _selectedFace;
                    final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null;
                    final ghToken = ref.read(remoteConfigProvider).githubFeedbackToken;
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
    );
  }
}
