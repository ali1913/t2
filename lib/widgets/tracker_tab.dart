import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/row_entry.dart';

const List<String> kColumnLabels = ['A', 'B', 'C', 'D', 'E'];
const String kRowsBoxName = 'rows_box';

// Flex ratios — Date gets more space than each single data column.
// Trash column is fixed-width (icon only).
const int kDateFlex = 3;
const int kDataFlex = 2;
const double kDeleteColWidth = 36;

class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  late final Box<RowEntry> _box;
  final ScrollController _vScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _box = Hive.box<RowEntry>(kRowsBoxName);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_vScroll.hasClients) {
      _vScroll.jumpTo(_vScroll.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _vScroll.dispose();
    super.dispose();
  }

  Future<void> _addRow(RowKind kind) async {
    List<num> values = List<num>.filled(kColumnLabels.length, 0);

    if (kind == RowKind.number) {
      // Number rows only ever count down, so ask for a starting value.
      final initial = await _promptInitialValue();
      if (initial == null) return; // cancelled
      values = List<num>.filled(kColumnLabels.length, initial);
    }

    final entry = RowEntry(date: DateTime.now(), kind: kind, values: values);
    _box.add(entry);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  Future<int?> _promptInitialValue() async {
    final controller = TextEditingController(text: '0');
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Starting value'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text) ?? 0),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(RowEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      entry.date = picked;
      entry.save();
      setState(() {});
    }
  }

  void _toggleCheckbox(RowEntry entry, int index) {
    entry.values[index] = entry.values[index] == 1 ? 0 : 1;
    entry.save();
    setState(() {});
  }

  void _decrementNumber(RowEntry entry, int index) {
    final current = entry.values[index];
    entry.values[index] = current > 0 ? current - 1 : 0;
    entry.save();
    setState(() {});
  }

  void _resetNumber(RowEntry entry, int index) {
    entry.values[index] = 0;
    entry.save();
    setState(() {});
  }

  void _deleteRow(RowEntry entry) {
    entry.delete();
    setState(() {});
  }

  List<num> _columnSums(List<RowEntry> entries) {
    final sums = List<num>.filled(kColumnLabels.length, 0);
    for (final entry in entries) {
      for (int i = 0; i < kColumnLabels.length; i++) {
        sums[i] += entry.values[i];
      }
    }
    return sums;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final entries = _box.values.toList();
    final sums = _columnSums(entries);

    return Column(
      children: [
        // Header + total row live outside the ListView so they stay pinned
        // while only the rows in between scroll.
        _buildHeaderRow(),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No rows yet.'))
              : ListView.builder(
                  controller: _vScroll,
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _buildDataRow(entries[index]),
                ),
        ),
        _buildFooterRow(sums),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Directionality(
            // Keep button order fixed left-to-right regardless of app RTL.
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(child: _pillButton(Icons.remove, Colors.green, () => _addRow(RowKind.checkbox))),
                const SizedBox(width: 12),
                Expanded(child: _pillButton(Icons.add, Colors.red, () => _addRow(RowKind.number))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillButton(IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _dataCell(int flex, Widget child) {
    return Expanded(flex: flex, child: Center(child: child));
  }

  Widget _buildHeaderRow() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _dataCell(kDateFlex, const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ...kColumnLabels.map(
            (l) => _dataCell(kDataFlex, Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          SizedBox(width: kDeleteColWidth),
        ],
      ),
    );
  }

  Widget _buildDataRow(RowEntry entry) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _dataCell(
            kDateFlex,
            GestureDetector(
              onTap: () => _pickDate(entry),
              child: Text(_formatDate(entry.date), style: const TextStyle(fontSize: 14)),
            ),
          ),
          ...List.generate(kColumnLabels.length, (i) {
            if (entry.kind == RowKind.checkbox) {
              final checked = entry.values[i] == 1;
              return _dataCell(
                kDataFlex,
                GestureDetector(
                  onTap: () => _toggleCheckbox(entry, i),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    checked ? Icons.check_rounded : Icons.close_rounded,
                    color: checked ? Colors.green : Colors.red,
                    size: 26,
                  ),
                ),
              );
            }
            return _dataCell(
              kDataFlex,
              GestureDetector(
                onTap: () => _decrementNumber(entry, i),
                onLongPress: () => _resetNumber(entry, i),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  '${entry.values[i]}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          }),
          SizedBox(
            width: kDeleteColWidth,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              padding: EdgeInsets.zero,
              onPressed: () => _deleteRow(entry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterRow(List<num> sums) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          top: BorderSide(color: Colors.green.shade300, width: 1.5),
          bottom: BorderSide(color: Colors.green.shade300, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _dataCell(kDateFlex, Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade800))),
          ...sums.map(
            (s) => _dataCell(kDataFlex, Text('$s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade800))),
          ),
          SizedBox(width: kDeleteColWidth),
        ],
      ),
    );
  }
}