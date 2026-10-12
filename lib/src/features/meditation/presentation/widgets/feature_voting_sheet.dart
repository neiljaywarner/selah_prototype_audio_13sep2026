import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/feedback/feedback_service.dart';
import 'emoji_feedback_dialog.dart';

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
  String _selectedSentiment = 'positive';
  int _selectedNps = 10;

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
      sentiment: _selectedSentiment,
      nps: _selectedNps,
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
              selectedSentiment: _selectedSentiment,
              onSentimentChanged: (s) => setState(() => _selectedSentiment = s),
              selectedNps: _selectedNps,
              onNpsChanged: (n) => setState(() => _selectedNps = n),
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
    required this.selectedSentiment,
    required this.onSentimentChanged,
    required this.selectedNps,
    required this.onNpsChanged,
    required this.onSubmit,
  });

  final TextEditingController feedbackController;
  final TextEditingController emailController;
  final bool isSubmitting;
  final String? statusMessage;
  final String selectedSentiment;
  final ValueChanged<String> onSentimentChanged;
  final int selectedNps;
  final ValueChanged<int> onNpsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEND DIRECT FEEDBACK (DOORBELL.IO REST)',
          style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Sentiment Selector
        const Text(
          'How is your experience today?',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _SentimentChip(
              label: 'Peaceful 🙏',
              sentimentKey: 'positive',
              isSelected: selectedSentiment == 'positive',
              onSelect: onSentimentChanged,
            ),
            const SizedBox(width: 6),
            _SentimentChip(
              label: 'Neutral 🕊️',
              sentimentKey: 'neutral',
              isSelected: selectedSentiment == 'neutral',
              onSelect: onSentimentChanged,
            ),
            const SizedBox(width: 6),
            _SentimentChip(
              label: 'Idea / Bug 💡',
              sentimentKey: 'negative',
              isSelected: selectedSentiment == 'negative',
              onSelect: onSentimentChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // NPS Rating Selector (1 to 10)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Peace / Helpful Rating (NPS):',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              '$selectedNps / 10',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (_, _) => const SizedBox(width: 5),
            itemBuilder: (ctx, idx) {
              final score = idx + 1;
              return _NpsScoreChip(
                score: score,
                isSelected: selectedNps == score,
                onSelect: onNpsChanged,
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Feedback text input
        TextField(
          controller: feedbackController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Share a suggestion, prayer, bug report, or encouragement...',
            filled: true,
            fillColor: const Color(0xFF0F0E26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Optional email input
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
            key: const Key('submit_doorbell_feedback_button'),
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Feedback to Doorbell.io'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('open_emoji_feedback_from_sheet_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Text('🕊️', style: TextStyle(fontSize: 14)),
                label: const Text('Emoji Reflection', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  rootNav.pop();
                  EmojiFeedbackDialog.show(rootNav.context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('copy_email_neil_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFBBF24),
                  side: BorderSide(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.email_outlined, size: 14, color: Color(0xFFFBBF24)),
                label: const Text('Email Neil Directly', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final feedbackText = feedbackController.text.trim();
                  Clipboard.setData(ClipboardData(
                    text: 'To: ${FeedbackService.defaultFeedbackEmail}\n'
                        'Subject: [Selah Feedback] Experience / Suggestion\n\n'
                        'Sentiment: $selectedSentiment\n'
                        'NPS: $selectedNps/10\n\n'
                        'Feedback:\n${feedbackText.isNotEmpty ? feedbackText : "(Enter your reflection/prayer here)"}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email copied! Send to neilwarner+selah@gmail.com',
                      ),
                      backgroundColor: Color(0xFF4338CA),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SentimentChip extends StatelessWidget {
  const _SentimentChip({
    required this.label,
    required this.sentimentKey,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final String sentimentKey;
  final bool isSelected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(sentimentKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _NpsScoreChip extends StatelessWidget {
  const _NpsScoreChip({
    required this.score,
    required this.isSelected,
    required this.onSelect,
  });

  final int score;
  final bool isSelected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(score),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF0F0E26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBBF24) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
