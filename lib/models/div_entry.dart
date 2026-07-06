import 'package:hive/hive.dart';

/// A row for the "division" tab: a date, a user-entered number, and a
/// derived value (input / 40) that is always computed, never stored.
class DivEntry extends HiveObject {
  DateTime date;
  num input;

  DivEntry({required this.date, required this.input});

  num get computed => input / 40;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'input': input,
      };

  factory DivEntry.fromJson(Map<String, dynamic> json) => DivEntry(
        date: DateTime.parse(json['date'] as String),
        input: json['input'] as num,
      );
}

/// Manual Hive adapter — avoids needing hive_generator + build_runner in CI.
/// typeId must be unique across all registered adapters (RowEntryAdapter
/// uses 0, so this one uses 1).
class DivEntryAdapter extends TypeAdapter<DivEntry> {
  @override
  final int typeId = 1;

  @override
  DivEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DivEntry(
      date: fields[0] as DateTime,
      input: fields[1] as num,
    );
  }

  @override
  void write(BinaryWriter writer, DivEntry obj) {
    writer
      ..writeByte(2) // number of fields
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.input);
  }
}
