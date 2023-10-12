import 'package:binarize/binarize.dart' as b;

enum ColumnType {
  integer,
  real,
  char,
  string,
  txtFile,
  intRange,
}

const columnDef = _Column();

abstract class DbColumn<T> {
  final String name;
  final ColumnType type;

  const DbColumn({required this.name, required this.type});

  b.PayloadType<T> get payloadType;
}

DbColumn createColumn({required String name, required ColumnType type}) {
  switch (type) {
    case ColumnType.integer:
      return IntegerColumn(name: name);
    case ColumnType.real:
      return RealColumn(name: name);
    case ColumnType.char:
      return CharColumn(name: name);
    case ColumnType.string:
      return StringColumn(name: name);
    case ColumnType.txtFile:
      return TextFileColumn(name: name);
    case ColumnType.intRange:
      return IntegerRangeColumn(name: name);
  }
}

class _Column extends b.PayloadType<DbColumn> {
  const _Column();

  @override
  int length(DbColumn value) {
    return 1 + b.string32.length(value.name);
  }

  @override
  DbColumn get(b.ByteData data, int offset) {
    final type = ColumnType.values[b.uint8.get(data, offset)];
    final name = b.string32.get(data, offset + 1);

    return createColumn(name: name, type: type);
  }

  @override
  void set(DbColumn value, b.ByteData data, int offset) {
    b.uint8.set(value.type.index, data, offset);
    b.string32.set(value.name, data, offset + 1);
  }
}

mixin ColumnPayload<T> {
  late final b.PayloadType<T> _payloadType;

  b.PayloadType<T> get payloadType => _payloadType;
}

class IntegerColumn extends DbColumn<int> with ColumnPayload<int> {
  IntegerColumn({required super.name}) : super(type: ColumnType.integer) {
    _payloadType = b.int64;
  }
}

class RealColumn extends DbColumn<double> with ColumnPayload<double> {
  RealColumn({required super.name}) : super(type: ColumnType.real) {
    _payloadType = b.float64;
  }
}

class CharColumn extends DbColumn<int> with ColumnPayload<int> {
  CharColumn({required super.name}) : super(type: ColumnType.char) {
    _payloadType = b.uint8;
  }
}

class StringColumn extends DbColumn<String> with ColumnPayload<String> {
  StringColumn({required super.name}) : super(type: ColumnType.string) {
    _payloadType = b.string32;
  }
}

class TextFile {
  final String path;
  final String content;
  const TextFile({required this.path, required this.content});
}

class TextFileColumn extends DbColumn<TextFile> with ColumnPayload<TextFile> {
  TextFileColumn({required super.name}) : super(type: ColumnType.txtFile) {
    _payloadType = textFilePayload;
  }
}

final textFilePayload = _TextFilePayload();

class _TextFilePayload extends b.PayloadType<TextFile> {
  @override
  int length(TextFile value) {
    return b.string32.length(value.path) + b.string32.length(value.content);
  }

  @override
  TextFile get(b.ByteData data, int offset) {
    final path = b.string32.get(data, offset);
    offset += b.string32.length(path);

    final content = b.string32.get(data, offset);
    return TextFile(path: path, content: content);
  }

  @override
  void set(TextFile value, b.ByteData data, int offset) {
    b.string32.set(value.path, data, offset);
    offset += b.string32.length(value.path);

    b.string32.set(value.content, data, offset);
  }
}

class IntegerRange {
  final int min;
  final int max;
  const IntegerRange({required this.min, required this.max});
}

class IntegerRangeColumn extends DbColumn<IntegerRange>
    with ColumnPayload<IntegerRange> {
  IntegerRangeColumn({required super.name}) : super(type: ColumnType.intRange) {
    _payloadType = integerRangePayload;
  }
}

final integerRangePayload = _IntegerRangePayload();

class _IntegerRangePayload extends b.PayloadType<IntegerRange> {
  @override
  int length(IntegerRange value) {
    return b.int64.length(value.min) + b.int64.length(value.max);
  }

  @override
  IntegerRange get(b.ByteData data, int offset) {
    return IntegerRange(
      min: b.int64.get(data, offset),
      max: b.int64.get(data, offset + b.int64.length(0)),
    );
  }

  @override
  void set(IntegerRange value, b.ByteData data, int offset) {
    b.int64.set(value.min, data, offset);
    b.int64.set(value.max, data, offset + b.int64.length(value.min));
  }
}
