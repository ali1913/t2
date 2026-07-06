import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/div_entry.dart';
import '../models/row_entry.dart';
import 'div_tab.dart' show kDivRowsBoxName;
import 'tracker_tab.dart' show kRowsBoxName;

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _busy = false;

  Future<void> _exportData() async {
    setState(() => _busy = true);
    try {
      final rowsBox = Hive.box<RowEntry>(kRowsBoxName);
      final divBox = Hive.box<DivEntry>(kDivRowsBoxName);

      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'trackerRows': rowsBox.values.map((e) => e.toJson()).toList(),
        'divRows': divBox.values.map((e) => e.toJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/tracker_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)], text: 'Tracker data export');
    } catch (e) {
      _showMessage('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import data'),
        content: const Text(
          'This will replace all current data in both tabs. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final rowsBox = Hive.box<RowEntry>(kRowsBoxName);
      final divBox = Hive.box<DivEntry>(kDivRowsBoxName);

      final trackerRows = (data['trackerRows'] as List? ?? [])
          .map((e) => RowEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final divRows = (data['divRows'] as List? ?? [])
          .map((e) => DivEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      await rowsBox.clear();
      await divBox.clear();
      await rowsBox.addAll(trackerRows);
      await divBox.addAll(divRows);

      _showMessage('Import complete (${trackerRows.length + divRows.length} rows)');
    } catch (e) {
      _showMessage('Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _busy
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Export Data'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Import Data'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
