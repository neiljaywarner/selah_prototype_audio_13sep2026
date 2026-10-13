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
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  TextInputType _keyboardType = TextInputType.text;
  bool _isBookIdentified = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final query = BibleCanon.parseQuery(val);
    if (query != null) {
      final shouldBeNumeric = (query.isExactBook && query.hasTrailingSpace) || (query.chapter != null);
      setState(() {
        _selectedBook = query.book;
        if (query.chapter != null && BibleCanon.isValidChapter(query.book.code, query.chapter!)) {
          _selectedChapter = query.chapter!;
        } else if (_selectedChapter > query.book.totalChapters) {
          _selectedChapter = 1;
        }
        _isBookIdentified = shouldBeNumeric;
        _keyboardType = shouldBeNumeric ? TextInputType.number : TextInputType.text;
        _searchQuery = query.isExactBook ? query.book.name : val;
      });
    } else {
      setState(() {
        _searchQuery = val;
        if (_isBookIdentified) {
          _isBookIdentified = false;
          _keyboardType = TextInputType.text;
        }
      });
    }
  }

  void _selectBook(BibleBook book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = 1;
      _isBookIdentified = true;
      _keyboardType = TextInputType.number;
      _searchController.text = '${book.name} ';
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
      _searchQuery = book.name;
    });
    _searchFocusNode.requestFocus();
  }

  void _submit() {
    Navigator.of(context).pop();
    widget.onChapterSelected(
      _selectedBook.code,
      _selectedChapter,
      _selectedBook.name,
    );
  }

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
      insetPadding: EdgeInsets.fromLTRB(
        16,
        20 + MediaQuery.paddingOf(context).top,
        16,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SafeArea(
        maintainBottomViewPadding: true,
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

            // Smart Search filter field with dynamic numeric keyboard switching
            TextField(
              key: ValueKey(_keyboardType),
              controller: _searchController,
              focusNode: _searchFocusNode,
              keyboardType: _keyboardType,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submit(),
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: _isBookIdentified
                    ? 'Type chapter (1 — ${_selectedBook.totalChapters}) & press Go...'
                    : 'Filter or type book (e.g. John, Rom, Ps)...',
                filled: true,
                fillColor: const Color(0xFF0F0E26),
                prefixIcon: Icon(
                  _isBookIdentified ? Icons.dialpad_rounded : Icons.search,
                  size: 18,
                  color: _isBookIdentified ? const Color(0xFFFBBF24) : Colors.white54,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_isBookIdentified) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_selectedBook.name} selected • Numeric keypad active for chapter (1—${_selectedBook.totalChapters})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Main Book Selection Grid
            Expanded(
              flex: 3,
              child: Material(
                color: const Color(0xFF0F0E26),
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
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
                      onTap: () => _selectBook(book),
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

