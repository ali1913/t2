import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/div_entry.dart';

const String kDivRowsBoxName = 'div_rows_box';

const int kDivDateFlex = 3;
const int kDivDataFlex = 2;
const double kDivDeleteColWidth = 36;
const double kDivRowHeight = 52;

class DivTab extends StatefulWidget {
  const DivTab({super.key});

  @override
  State<DivTab> createState() => _DivTabState();
}

class _DivTabState extends State<DivTab> {
  late final Box<DivEntry> _box;
  final ScrollController _vScroll = ScrollController();

  // One controller per row (keyed by Hive key) so typing in the input
  // column doesn't lose cursor position on rebuild.
  final Map<dynamic, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _box = Hive.box<DivEntry>(kDivRowsBoxName);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_vScroll.hasClients) {
      _vScroll.jumpTo(_vScroll.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _vScroll.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(DivEntry entry) {
    return _controllers.putIfAbsent(
      entry.key,
      () => TextEditingController(text: _fmt(entry.input)),
    );
  }

  void _addRow() {
    final entry = DivEntry(date: DateTime.now(), input: 0);
    _box.add(entry);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  Future<void> _pickDate(DivEntry entry) async {
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

  void _updateInput(DivEntry entry, String text) {
    entry.input = num.tryParse(text) ?? 0;
    entry.save();
    setState(() {}); // recompute the derived column + totals
  }

  void _deleteRow(DivEntry entry) {
    _controllers.remove(entry.key)?.dispose();
    entry.delete();
    setState(() {});
  }

  (num, num) _columnSums(List<DivEntry> entries) {
    num inputSum = 0;
    num computedSum = 0;
    for (final e in entries) {
      inputSum += e.input;
      computedSum += e.computed;
    }
    return (inputSum, computedSum);
  }

  String _fmt(num n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _dataCell(int flex, Widget child) {
    return Expanded(flex: flex, child: Center(child: child));
  }

  Widget _gestureCell(int flex, Widget child, {VoidCallback? onTap}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _box.values.toList();
    final (inputSum, computedSum) = _columnSums(entries);

    return Column(
      children: [
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
        _buildFooterRow(inputSum, computedSum),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Row'),
            ),
          ),
        ),
      ],
    );
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
          _dataCell(kDivDateFlex, const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          _dataCell(kDivDataFlex, const Text('Input', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          _dataCell(kDivDataFlex, const Text('÷ 40', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          SizedBox(width: kDivDeleteColWidth),
        ],
      ),
    );
  }

  Widget _buildDataRow(DivEntry entry) {
    return Container(
      height: kDivRowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _gestureCell(
            kDivDateFlex,
            Text(_formatDate(entry.date), style: const TextStyle(fontSize: 14)),
            onTap: () => _pickDate(entry),
          ),
          _dataCell(
            kDivDataFlex,
            TextField(
              controller: _controllerFor(entry),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (text) => _updateInput(entry, text),
            ),
          ),
          _dataCell(
            kDivDataFlex,
            Text(
              _fmt(entry.computed),
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          SizedBox(
            width: kDivDeleteColWidth,
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

  Widget _buildFooterRow(num inputSum, num computedSum) {
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
          _dataCell(kDivDateFlex, Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade800))),
          _dataCell(kDivDataFlex, Text(_fmt(inputSum), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade800))),
          _dataCell(kDivDataFlex, Text(_fmt(computedSum), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade800))),
          SizedBox(width: kDivDeleteColWidth),
        ],
      ),
    );
  }
}
