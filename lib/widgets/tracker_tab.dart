import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/row_entry.dart';

const List<String> kColumnLabels = ['A', 'B', 'C', 'D', 'E'];
const String kRowsBoxName = 'rows_box';

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

  @override
  void initState() {
    super.initState();
    _box = Hive.box<RowEntry>(kRowsBoxName);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
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
    setState(() {}); // recompute the sum row
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
          child: entries.isEmpty
              ? const Center(child: Text('No rows yet. Add one above.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Date')),
                        ...kColumnLabels.map((l) => DataColumn(label: Text(l))),
                        const DataColumn(label: Text('')),
                      ],
                      rows: [
                        ...entries.map((entry) => _buildRow(entry)),
                        _buildSumRow(sums),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  DataRow _buildRow(RowEntry entry) {
    return DataRow(
      cells: [
        DataCell(
          Text(_formatDate(entry.date)),
          onTap: () => _pickDate(entry),
        ),
        ...List.generate(kColumnLabels.length, (i) {
          if (entry.kind == RowKind.checkbox) {
            return DataCell(
              Checkbox(
                value: entry.values[i] == 1,
                onChanged: (_) => _toggleCheckbox(entry, i),
              ),
            );
          }
          return DataCell(
            SizedBox(
              width: 56,
              child: TextField(
                controller: _controllerFor(entry, i),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true),
                onChanged: (text) => _updateNumber(entry, i, text),
              ),
            ),
          );
        }),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteRow(entry),
          ),
        ),
      ],
    );
  }

  DataRow _buildSumRow(List<num> sums) {
    return DataRow(
      color: MaterialStateProperty.all(Colors.grey.shade200),
      cells: [
        const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        ...sums.map(
          (s) => DataCell(Text('$s', style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
        const DataCell(Text('')),
      ],
    );
  }
}