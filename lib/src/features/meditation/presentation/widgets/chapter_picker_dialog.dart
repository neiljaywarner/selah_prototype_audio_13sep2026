import 'package:flutter/material.dart';
import '../../../../core/constants/bible_canon.dart';

class ChapterPickerDialog extends StatefulWidget {
  final void Function(String bookCode, int chapterNumber, String bookName) onChapterSelected;

  const ChapterPickerDialog({super.key, required this.onChapterSelected});

  @override
  State<ChapterPickerDialog> createState() => _ChapterPickerDialogState();
}

class _ChapterPickerDialogState extends State<ChapterPickerDialog> {
  String _filter = 'all'; // 'all', 'ot', 'nt'
  String _searchQuery = '';
  BibleBook _selectedBook = BibleCanon.books[0]; // Genesis
  int _selectedChapter = 1;

  @override
  Widget build(BuildContext context) {
    final filteredBooks = BibleCanon.books.where((b) {
      if (_filter == 'ot' && !b.isOldTestament) return false;
      if (_filter == 'nt' && b.isOldTestament) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return b.name.toLowerCase().contains(q) || b.code.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1B4B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, color: Color(0xFFFBBF24), size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Browse 66 Books & Chapters',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
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
            const SizedBox(height: 12),

            // Testament filter segments
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipItem(
                    label: 'All (66)',
                    filterKey: 'all',
                    isSelected: _filter == 'all',
                    onSelect: (k) => setState(() => _filter = k),
                  ),
                  const SizedBox(width: 6),
                  _FilterChipItem(
                    label: 'Old Testament (39)',
                    filterKey: 'ot',
                    isSelected: _filter == 'ot',
                    onSelect: (k) => setState(() => _filter = k),
                  ),
                  const SizedBox(width: 6),
                  _FilterChipItem(
                    label: 'New Testament (27)',
                    filterKey: 'nt',
                    isSelected: _filter == 'nt',
                    onSelect: (k) => setState(() => _filter = k),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search filter field
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Filter book name (e.g. Psalms, John, Colossians)...',
                filled: true,
                fillColor: const Color(0xFF0F0E26),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Main Book Selection Grid
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0E26),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredBooks.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (ctx, idx) {
                    final book = filteredBooks[idx];
                    final isSelected = book.code == _selectedBook.code;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      title: Text(
                        book.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFFFBBF24) : Colors.white,
                        ),
                      ),
                      trailing: Text(
                        '${book.totalChapters} ch',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedBook = book;
                          if (_selectedChapter > book.totalChapters) {
                            _selectedChapter = 1;
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chapter Picker for Selected Book
            Text(
              'SELECT CHAPTER (1 — ${_selectedBook.totalChapters})',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedBook.totalChapters,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final chNum = idx + 1;
                  final isSelected = _selectedChapter == chNum;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChapter = chNum),
                    child: Container(
                      width: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$chNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onChapterSelected(
                  _selectedBook.code,
                  _selectedChapter,
                  _selectedBook.name,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Play ${_selectedBook.name} $_selectedChapter',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.filterKey,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final String filterKey;
  final bool isSelected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

