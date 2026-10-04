import 'package:flutter/material.dart';
import '../../../../core/feedback/feedback_service.dart';

class FeatureVotingSheet extends StatefulWidget {
  const FeatureVotingSheet({super.key});

  @override
  State<FeatureVotingSheet> createState() => _FeatureVotingSheetState();
}

class _FeatureVotingSheetState extends State<FeatureVotingSheet> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final msg = _feedbackController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    final success = await FeedbackService.submitDoorbellFeedback(
      message: msg,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );

    setState(() {
      _isSubmitting = false;
      if (success) {
        _feedbackController.clear();
        _statusMessage = 'Thank you! Your feedback has been received. 🙏';
      } else {
        _statusMessage = 'Feedback saved locally. Thank you! 🙏';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final features = FeedbackService.defaultRoadmapFeatures;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1B4B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.how_to_vote_rounded, color: Color(0xFFFBBF24), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Feature Roadmap & Feedback',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Vote for the next features you want in Selah, or send us a personal prayer / suggestion.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const Divider(color: Colors.white12, height: 24),

            const Text(
              'COMMUNITY FEATURE VOTING',
              style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...features.map((feature) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0E26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: feature.hasVoted ? const Color(0xFFFBBF24) : Colors.white10,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          FeedbackService.castVote(feature);
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: feature.hasVoted
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: feature.hasVoted ? Colors.black : Colors.white70,
                            ),
                            Text(
                              '${feature.votes}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: feature.hasVoted ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  feature.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  feature.targetVersion,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFFBBF24)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description,
                            style: const TextStyle(fontSize: 11, color: Colors.white60, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(color: Colors.white12, height: 28),

            const Text(
              'SEND DIRECT FEEDBACK (DOORBELL.IO READY)',
              style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _feedbackController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share a suggestion, bug report, or encouragement...',
                filled: true,
                fillColor: const Color(0xFF0F0E26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Email (optional, for reply)',
                filled: true,
                fillColor: const Color(0xFF0F0E26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
