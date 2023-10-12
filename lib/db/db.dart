import 'dart:async';
import 'dart:io';

import 'package:binarize/binarize.dart';
import 'package:unidb/db/columns.dart';
import 'package:unidb/db/db_schema.dart';
import 'package:unidb/db/table.dart';

class DbLoadError extends Error {
  final String message;

  DbLoadError(this.message) : super();
}

class Db {
  final String path;
  late File file;
  final DbSchema schema;
  DateTime lastSaved;
  int size;

  Db._({
    required this.path,
    required this.schema,
    required this.lastSaved,
    required this.size,
    File? file,
  }) {
    this.file = file ?? File(path);
  }

  void addTable({
    required String name,
    required Iterable<({String name, ColumnType type})> columns,
  }) {
    final tableColumns =
        columns.map((e) => createColumn(name: e.name, type: e.type)).toList();
    schema.tables[name] = Table.create(name: name, columns: tableColumns);
  }

  void removeTable(String name) {
    schema.tables.remove(name);
  }

  Future<void> save() async {
    if (!await file.exists()) {
      file = await file.create(recursive: true);
    }

    lastSaved = DateTime.now();

    final payload = Payload.write();
    payload.set(dbSchemaDef, schema);
    payload.set(int64, lastSaved.millisecondsSinceEpoch);
    final bytes = binarize(payload);

    size = bytes.length;

    await file.writeAsBytes(bytes);
  }

  static Future<Db> create({required String path, required String name}) async {
    final file = File(path);
    if (await file.exists()) {
      throw DbLoadError('Database already exists');
    }

    final schema = DbSchema(name: name, tables: {});
    final db = Db._(
        path: path,
        schema: schema,
        file: file,
        lastSaved: DateTime.now(),
        size: 0);
    await db.save();

    return db;
  }

  static FutureOr<Db> load(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw DbLoadError('Database does not exist');
    }

    final bytes = await file.readAsBytes();
    final payload = Payload.read(bytes);
    final schema = payload.get(dbSchemaDef);
    final lastSaved = DateTime.fromMillisecondsSinceEpoch(payload.get(int64));

    return Db._(
        path: path,
        schema: schema,
        file: file,
        lastSaved: lastSaved,
        size: bytes.length);
  }
}
