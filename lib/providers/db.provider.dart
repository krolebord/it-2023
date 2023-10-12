import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:unidb/db/columns.dart';
import 'package:unidb/db/db.dart';
import 'package:unidb/db/db_schema.dart';
import 'package:unidb/db/table.dart';
import 'package:window_size/window_size.dart';

class DbLoaderNotifier extends ChangeNotifier {
  DbLoaderNotifier();

  Db? db;

  Future<void> openDb() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select database file',
      allowMultiple: false,
      allowedExtensions: ['db'],
      type: FileType.custom,
    );

    if (result == null ||
        result.count < 1 ||
        result.files.firstOrNull?.path == null) {
      db = null;
      notifyListeners();
      return;
    }

    final path = result.files.first.path!;
    db = await Db.load(path);
    setWindowTitle("DBMS - ${db!.schema.name}");
    notifyListeners();
  }

  Future<void> createDb({required String name}) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Create new database file',
      fileName: '$name.db',
      allowedExtensions: ['db'],
      type: FileType.custom,
    );

    if (result == null) {
      db = null;
      notifyListeners();
      return;
    }

    db = await Db.create(path: result, name: name);
    setWindowTitle("DBMS - ${db!.schema.name}");
    notifyListeners();
  }

  void closeDb() {
    db = null;
    setWindowTitle("DBMS");
    notifyListeners();
  }
}

class DbNotifier extends ChangeNotifier {
  DbNotifier(Db db) : _db = db;

  final Db _db;

  DbSchema get schema => _db.schema;
  DateTime get lastSaved => _db.lastSaved;
  int get size => _db.size;

  Future<void> save() async {
    await _db.save();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void addTable(
      {required String name,
      required Iterable<({String name, ColumnType type})> columns}) {
    _db.addTable(name: name, columns: columns);
    notifyListeners();
  }

  void removeTable(String name) {
    _db.removeTable(name);
    notifyListeners();
  }
}

class TableNotifier extends ChangeNotifier {
  final Table table;

  TableNotifier(this.table);

  void addRow(Map<String, Object?> row) {
    table.addRow(row);
    notifyListeners();
  }

  void updateRow(int id, Map<String, Object?> row) {
    table.updateRow(id, row);
    notifyListeners();
  }

  void removeRow(int id) {
    table.removeRow(id);
    notifyListeners();
  }

  void duplicateRow(int id) {
    table.duplicateRow(id);
    notifyListeners();
  }
}

final dbLoaderProvider = ChangeNotifierProvider((ref) => DbLoaderNotifier());
final dbProvider =
    ChangeNotifierProvider<DbNotifier>((ref) => throw UnimplementedError());
final tableProvider = ChangeNotifierProvider.autoDispose
    .family<TableNotifier, String>((ref, tableName) {
  final db = ref.watch(dbProvider);
  final table = db.schema.tables[tableName];

  if (table == null) {
    throw Exception('Table $tableName does not exist');
  }

  return TableNotifier(table);
}, dependencies: [dbProvider]);
