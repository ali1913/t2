import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/row_entry.dart';

const List<String> kColumnLabels = ['A', 'B', 'C', 'D', 'E'];
const String kRowsBoxName = 'rows_box';

// Fixed column widths — keeps columns compact instead of relying on
// DataTable's built-in padding (which is hard to shrink below ~56px/col).
const double kDateColWidth = 86;
const double kDataColWidth = 42;
const double kDeleteColWidth = 40;

class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  late final Box<RowEntry> _box;

  // One TextEditingController per (rowKey, columnIndex) so typing doesn't
  // lose cursor position or get reset on rebuild.
  final Map<String, TextEditingController> _controllers = {};

  final ScrollController _vScroll = ScrollController();
  final ScrollController _hScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _box = Hive.box<RowEntry>(kRowsBoxName);
    // Land on the most recent rows / far edge instead of the top-left.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    for (final controller in [_vScroll, _hScroll]) {
      if (controller.hasClients) {
        controller.jumpTo(controller.position.maxScrollExtent);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _vScroll.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(RowEntry entry, int colIndex) {
    final key = '${entry.key}_$colIndex';
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: entry.values[colIndex].toString()),
    );
  }

  void _addRow(RowKind kind) {
    final entry = RowEntry(
      date: DateTime.now(),
      kind: kind,
      values: List<num>.filled(kColumnLabels.length, 0),
    );
    _box.add(entry);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
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

  void _updateNumber(RowEntry entry, int index, String text) {
    entry.values[index] = int.tryParse(text) ?? 0;
    entry.save();
    setState(() {});
  }

  void _deleteRow(RowEntry entry) {
    _controllers.removeWhere((key, controller) {
      final match = key.startsWith('${entry.key}_');
      if (match) controller.dispose();
      return match;
    });
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

  double get _tableWidth =>
      kDateColWidth + (kDataColWidth * kColumnLabels.length) + kDeleteColWidth;

  @override
  Widget build(BuildContext context) {
    final entries = _box.values.toList();
    final sums = _columnSums(entries);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _addRow(RowKind.checkbox),
                icon: const Icon(Icons.check_box_outlined),
                label: const Text('Add Checkbox Row'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _addRow(RowKind.number),
                icon: const Icon(Icons.numbers),
                label: const Text('Add Number Row'),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _tableWidth,
                  height: constraints.maxHeight,
                  // Header + total row are outside the vertical ListView,
                  // so they stay pinned while only the middle scrolls.
                  child: Column(
                    children: [
                      _buildHeaderRow(),
                      Expanded(
                        child: entries.isEmpty
                            ? const Center(child: Text('No rows yet.'))
                            : ListView.builder(
                                controller: _vScroll,
                                itemCount: entries.length,
                                itemBuilder: (context, index) =>
                                    _buildDataRow(entries[index]),
                              ),
                      ),
                      _buildFooterRow(sums),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cellBox(double width, Widget child) {
    return SizedBox(width: width, child: Center(child: child));
  }

  Widget _buildHeaderRow() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        children: [
          _cellBox(kDateColWidth,
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          ...kColumnLabels.map(
            (l) => _cellBox(kDataColWidth,
                Text(l, style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          _cellBox(kDeleteColWidth, const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildDataRow(RowEntry entry) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _cellBox(
            kDateColWidth,
            InkWell(
              onTap: () => _pickDate(entry),
              child: Text(_formatDate(entry.date), style: const TextStyle(fontSize: 12)),
            ),
          ),
          ...List.generate(kColumnLabels.length, (i) {
            if (entry.kind == RowKind.checkbox) {
              return _cellBox(
                kDataColWidth,
                Checkbox(
                  value: entry.values[i] == 1,
                  onChanged: (_) => _toggleCheckbox(entry, i),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }
            return _cellBox(
              kDataColWidth,
              TextField(
                controller: _controllerFor(entry, i),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (text) => _updateNumber(entry, i, text),
              ),
            );
          }),
          _cellBox(
            kDeleteColWidth,
            IconButton(
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
        color: Colors.grey.shade200,
        border: Border(top: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        children: [
          _cellBox(kDateColWidth,
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ...sums.map(
            (s) => _cellBox(kDataColWidth,
                Text('$s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          _cellBox(kDeleteColWidth, const SizedBox.shrink()),
        ],
      ),
    );
  }
}