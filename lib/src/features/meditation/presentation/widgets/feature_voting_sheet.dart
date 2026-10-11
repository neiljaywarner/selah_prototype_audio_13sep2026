import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/feedback/feedback_service.dart';

class FeatureVotingSheet extends ConsumerStatefulWidget {
  const FeatureVotingSheet({super.key});

  @override
  ConsumerState<FeatureVotingSheet> createState() => _FeatureVotingSheetState();
}

class _FeatureVotingSheetState extends ConsumerState<FeatureVotingSheet> {
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
    final votingState = ref.watch(featureVotingProvider);
    final votingNotifier = ref.read(featureVotingProvider.notifier);

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COMMUNITY FEATURE VOTING',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                ),
                if (votingState.isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6366F1)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            ...votingState.features.map(
              (feature) => _FeatureVotingTile(
                feature: feature,
                onVote: () => votingNotifier.toggleVote(feature.id),
              ),
            ),

            const Divider(color: Colors.white12, height: 28),

            _DirectFeedbackSection(
              feedbackController: _feedbackController,
              emailController: _emailController,
              isSubmitting: _isSubmitting,
              statusMessage: _statusMessage,
              onSubmit: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureVotingTile extends StatelessWidget {
  const _FeatureVotingTile({
    required this.feature,
    required this.onVote,
  });

  final RoadmapFeatureItem feature;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
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
          _VoteButton(
            votes: feature.votes,
            hasVoted: feature.hasVoted,
            onTap: onVote,
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
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.votes,
    required this.hasVoted,
    required this.onTap,
  });

  final int votes;
  final bool hasVoted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hasVoted ? const Color(0xFFFBBF24) : const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasVoted ? const Color(0xFFFBBF24) : Colors.white12,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: hasVoted ? Colors.black : Colors.white70,
              ),
              const SizedBox(height: 2),
              Text(
                '$votes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasVoted ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectFeedbackSection extends StatelessWidget {
  const _DirectFeedbackSection({
    required this.feedbackController,
    required this.emailController,
    required this.isSubmitting,
    required this.statusMessage,
    required this.onSubmit,
  });

  final TextEditingController feedbackController;
  final TextEditingController emailController;
  final bool isSubmitting;
  final String? statusMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEND DIRECT FEEDBACK (DOORBELL.IO READY)',
          style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: feedbackController,
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
          controller: emailController,
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
        if (statusMessage != null) ...[
          Text(
            statusMessage!,
            style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
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
    );
  }
}
