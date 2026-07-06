import 'package:hive/hive.dart';

/// The two kinds of rows the table supports.
enum RowKind { checkbox, number }

/// A single row in the tracker table.
///
/// Columns A..E are stored as a fixed-length list of 5 numbers:
/// - For [RowKind.checkbox] rows, each value is 0 (unchecked) or 1 (checked).
/// - For [RowKind.number] rows, each value is an arbitrary integer.
///
/// Storing both kinds as `num` lets the sum row simply add every column
/// together regardless of row type.
class RowEntry extends HiveObject {
  DateTime date;
  RowKind kind;
  List<num> values; // length 5: [a, b, c, d, e]

  RowEntry({
    required this.date,
    required this.kind,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'kind': kind.name,
        'values': values,
      };

  factory RowEntry.fromJson(Map<String, dynamic> json) => RowEntry(
        date: DateTime.parse(json['date'] as String),
        kind: RowKind.values.byName(json['kind'] as String),
        values: (json['values'] as List).map((e) => e as num).toList(),
      );
}

/// Manual Hive adapter — avoids needing hive_generator + build_runner in CI.
class RowEntryAdapter extends TypeAdapter<RowEntry> {
  @override
  final int typeId = 0;

  @override
  RowEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RowEntry(
      date: fields[0] as DateTime,
      kind: RowKind.values[fields[1] as int],
      values: (fields[2] as List).map((e) => e as num).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, RowEntry obj) {
    writer
      ..writeByte(3) // number of fields
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.kind.index)
      ..writeByte(2)
      ..write(obj.values);
  }
}
