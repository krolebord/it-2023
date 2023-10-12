import 'dart:collection';

import 'package:binarize/binarize.dart';
import 'package:unidb/db/columns.dart';

class Table {
  final String name;

  late int _idCounter;
  late final List<DbColumn> _columns;
  late final Map<int, List<Object>> _data;

  UnmodifiableListView<DbColumn> get columns =>
      UnmodifiableListView<DbColumn>(_columns);
  UnmodifiableListView<List<Object>> get rows =>
      UnmodifiableListView<List<Object>>(_data.values.toList());

  Table.create({required this.name, required Iterable<DbColumn> columns}) {
    _columns = [IntegerColumn(name: '\$id')];
    _columns.addAll(columns);
    _idCounter = 0;
    _data = {};
  }

  Table.load(
      {required this.name,
      required List<DbColumn> columns,
      required Map<int, List<Object>> data,
      required int idCounter}) {
    _columns = columns;
    _idCounter = idCounter;
    _data = data;
  }

  void addRow(Map<String, Object?> row) {
    final id = _idCounter++;
    _data[id] = _columns.map((e) {
      if (e.name == '\$id') {
        return id;
      }

      final cell = row[e.name];
      if (cell == null) {
        return throw Exception('Column ${e.name} is missing');
      }
      return cell;
    }).toList();
  }

  void updateRow(int id, Map<String, Object?> row) {
    _data[id] = _columns.map((e) {
      if (e.name == '\$id') {
        return id;
      }

      final cell = row[e.name];
      if (cell == null) {
        return throw Exception('Column ${e.name} is missing');
      }
      return cell;
    }).toList();
  }

  void removeRow(int id) {
    _data.remove(id);
  }

  void duplicateRow(int id) {
    final newId = _idCounter++;
    _data[newId] = List.from(_data[id]!);
    _data[newId]![0] = newId;
  }
}

final columnsDef = list(columnDef);
const tableDef = _Table();

class _Table extends PayloadType<Table> {
  const _Table();

  @override
  int length(Table value) {
    return string32.length(value.name) +
        columnsDef.length(value._columns) +
        int64.length(value._idCounter) +
        map(int64, _Row(value._columns)).length(value._data);
  }

  @override
  Table get(ByteData data, int offset) {
    final name = string32.get(data, offset);
    offset += string32.length(name);

    final cols = columnsDef.get(data, offset);
    offset += columnsDef.length(cols);

    final idCounter = int64.get(data, offset);
    offset += int64.length(idCounter);

    final rows = map(int64, _Row(cols)).get(data, offset);

    return Table.load(
        name: name, columns: cols, data: rows, idCounter: idCounter);
  }

  @override
  void set(Table value, ByteData data, int offset) {
    string32.set(value.name, data, offset);
    offset += string32.length(value.name);

    columnsDef.set(value._columns, data, offset);
    offset += columnsDef.length(value._columns);

    int64.set(value._idCounter, data, offset);
    offset += int64.length(value._idCounter);

    map(int64, _Row(value._columns)).set(value._data, data, offset);
  }
}

class _Row extends PayloadType<List<Object>> {
  final List<DbColumn> columns;

  const _Row(this.columns);

  @override
  int length(List<Object> value) {
    return columns.asMap().entries.fold(
        0,
        (previousValue, element) =>
            previousValue +
            element.value.payloadType.length(value[element.key]));
  }

  @override
  List<Object> get(ByteData data, int offset) {
    final row = <Object>[];
    for (final col in columns) {
      final value = col.payloadType.get(data, offset);
      row.add(col.payloadType.get(data, offset));
      offset += col.payloadType.length(value);
    }
    return row;
  }

  @override
  void set(List<Object> value, ByteData data, int offset) {
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      col.payloadType.set(value[i], data, offset);
      offset += col.payloadType.length(value[i]);
    }
  }
}
