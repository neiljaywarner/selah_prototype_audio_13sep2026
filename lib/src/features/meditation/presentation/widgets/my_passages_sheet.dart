import 'package:flutter/material.dart';

import '../../../../core/preferences/saved_passage.dart';

/// Saved passages the listener can open again or send to a friend.
///
/// Each row shows the stored reference. Sharing sends that reference, not
/// the verse text.
class MyPassagesSheet extends StatelessWidget {
  const MyPassagesSheet({
    super.key,
    required this.passages,
    required this.onShare,
    required this.onOpen,
    required this.onRemove,
  });

  final List<SavedPassage> passages;
  final ValueChanged<String> onShare;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'My Passages',
              key: Key('my_passages_sheet'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share a reference. Your friend opens it in Selah and can listen without an account.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (passages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No saved passages yet. Bookmark the passage you are hearing, then share it from here.',
                  key: Key('my_passages_empty'),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: passages.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final passage = passages[index];
                    final query = passage.query;
                    return Semantics(
                      identifier: 'open_my_passage_$query',
                      button: true,
                      label: query,
                      child: ListTile(
                        key: Key('my_passage_$query'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          query,
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => onOpen(query),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('share_my_passage_$query'),
                              tooltip: 'Share $query',
                              onPressed: () => onShare(query),
                              icon: const Icon(
                                Icons.ios_share_rounded,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                            IconButton(
                              key: Key('remove_my_passage_$query'),
                              tooltip: 'Remove $query',
                              onPressed: () => onRemove(query),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
