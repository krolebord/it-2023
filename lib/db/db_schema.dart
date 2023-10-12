import 'package:binarize/binarize.dart';
import 'package:unidb/db/table.dart';

class DbSchema {
  final String name;
  final Map<String, Table> tables;

  const DbSchema({required this.name, required this.tables});
}

final tablesDef = map(string32, tableDef);
const dbSchemaDef = _DbSchema();

class _DbSchema extends PayloadType<DbSchema> {
  const _DbSchema();

  @override
  int length(DbSchema value) {
    return string32.length(value.name) + tablesDef.length(value.tables);
  }

  @override
  DbSchema get(ByteData data, int offset) {
    final name = string32.get(data, offset);
    offset += string32.length(name);

    final tables = tablesDef.get(data, offset);

    return DbSchema(name: name, tables: tables);
  }

  @override
  void set(DbSchema value, ByteData data, int offset) {
    string32.set(value.name, data, offset);
    offset += string32.length(value.name);

    tablesDef.set(value.tables, data, offset);
  }
}
