import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/feedback/feedback_service.dart';

/// Modal dialog allowing users to leave quick emoji or star ratings,
/// meditative reflections, or send private feedback directly to Neil.
class EmojiFeedbackDialog extends StatefulWidget {
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
  State<EmojiFeedbackDialog> createState() => _EmojiFeedbackDialogState();
}

class _EmojiFeedbackDialogState extends State<EmojiFeedbackDialog> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int _selectedRating = 5;
  String _selectedEmoji = '🕊️';
  String _selectedLabel = 'Peaceful';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<Map<String, dynamic>> _emojiOptions = [
    {'emoji': '🕊️', 'label': 'Peaceful', 'rating': 5},
    {'emoji': '🙏', 'label': 'Grateful', 'rating': 4},
    {'emoji': '💛', 'label': 'Comforted', 'rating': 3},
    {'emoji': '😐', 'label': 'Neutral', 'rating': 2},
    {'emoji': '🌧️', 'label': 'Distracted', 'rating': 1},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    await FeedbackService.submitFeedback(
      rating: _selectedRating,
      emoji: _selectedEmoji,
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
    final body = 'Rating: $_selectedRating/5 $_selectedEmoji ($_selectedLabel)\n\n'
        'Passage: ${widget.currentChapter ?? "N/A"}\n'
        'Translation: ${widget.translation ?? "N/A"}\n\n'
        'Reflection / Feedback:\n$comment';

    Clipboard.setData(ClipboardData(
      text: 'To: ${FeedbackService.defaultFeedbackEmail}\nSubject: [Selah Feedback] $_selectedEmoji $_selectedLabel\n\n$body',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Email template copied to clipboard! You can also email directly to neilwarner+selah@gmail.com',
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
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🕊️', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank You!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your prayer and reflection help shape Selah for brothers and sisters around the world.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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

    return Dialog(
      backgroundColor: const Color(0xFF161536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade700.withValues(alpha: 0.5)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
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
                    const Text('🕊️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How was your meditation?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Share your reflection or feedback',
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

                // Emoji Reaction Row
                const Text(
                  'SELECT YOUR EXPERIENCE',
                  style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _emojiOptions.map((opt) {
                    final isSel = _selectedRating == opt['rating'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          key: Key('emoji_rating_${opt['rating']}'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _selectedRating = opt['rating'] as int;
                              _selectedEmoji = opt['emoji'] as String;
                              _selectedLabel = opt['label'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? const Color(0xFFFBBF24) : Colors.white10,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(opt['emoji'] as String, style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  opt['label'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
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

                // Star Rating Representation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFFBBF24),
                        size: 26,
                      ),
                      onPressed: () {
                        final match = _emojiOptions.firstWhere(
                          (e) => e['rating'] == starIndex,
                          orElse: () => _emojiOptions.first,
                        );
                        setState(() {
                          _selectedRating = starIndex;
                          _selectedEmoji = match['emoji'] as String;
                          _selectedLabel = match['label'] as String;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Reflection comment input
                TextField(
                  key: const Key('feedback_comment_field'),
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Share a prayer request, suggestion, or request a passage...',
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
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),

                // Email field
                TextField(
                  key: const Key('feedback_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Your email (optional, if you want a reply)',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                ElevatedButton(
                  key: const Key('submit_feedback_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Reflection', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  key: const Key('email_direct_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.email_outlined, size: 16, color: Color(0xFFFBBF24)),
                  label: const Text('Copy Email to Neil Warner', style: TextStyle(fontSize: 12)),
                  onPressed: _handleEmailDirect,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
