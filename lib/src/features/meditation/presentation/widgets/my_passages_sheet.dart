import 'package:flutter/material.dart';

import '../../domain/passage_share.dart';

/// Saved passages the listener can open again or send to a friend.
///
/// Each row shares the reference, not the verse text stored nowhere in this
/// list.
class MyPassagesSheet extends StatelessWidget {
  const MyPassagesSheet({
    super.key,
    required this.savedReferences,
    required this.onShare,
    required this.onOpen,
  });

  final List<String> savedReferences;
  final ValueChanged<String> onShare;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = PassageShareLink.itemsFromSaved(savedReferences);
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
            if (items.isEmpty)
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
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final reference = item.passage.canonical;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reference,
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => onOpen(reference),
                      trailing: IconButton(
                        key: Key('share_my_passage_$reference'),
                        tooltip: 'Share $reference',
                        onPressed: () => onShare(reference),
                        icon: const Icon(Icons.ios_share_rounded, color: Color(0xFFFBBF24)),
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
