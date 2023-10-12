import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unidb/db/columns.dart';
import 'package:unidb/db/db.dart';

Future<void> main() async {
  test('DB serialization', () async {
    final fileSystem = MemoryFileSystem();
    final db = await Db.create(
        fileSystem: fileSystem, path: '/path/to/file.db', name: 'test db');

    db.addTable(
      name: 'table 1',
      columns: [
        (name: 'int', type: ColumnType.integer),
        (name: 'real', type: ColumnType.real),
        (name: 'char', type: ColumnType.char),
        (name: 'str', type: ColumnType.string),
        (name: 'int intvl', type: ColumnType.intRange),
        (name: 'txt', type: ColumnType.txtFile),
      ],
    );

    db.schema.tables['table 1']!.addRow({
      'int': 1,
      'real': 2.2,
      'char': 44,
      'str': 'str',
      'int intvl': const IntegerRange(min: 1, max: 2),
      'txt': const TextFile(path: 'file.txt', content: 'content'),
    });

    await db.save(fileSystem: fileSystem);

    final loadedDb =
        await Db.load(path: '/path/to/file.db', fileSystem: fileSystem);

    expect(loadedDb.schema.name, db.schema.name);
    expect(loadedDb.schema.tables.keys, db.schema.tables.keys);

    final row = db.schema.tables['table 1']!.rows.first;
    final loadedRow = loadedDb.schema.tables['table 1']!.rows.first;

    expect(row[0], loadedRow[0]);
    expect(row[1], loadedRow[1]);
    expect(row[2], loadedRow[2]);
    expect(row[3], loadedRow[3]);
  });

  test('Db load throw when file does not exist', () async {
    final fileSystem = MemoryFileSystem();
    expect(Db.load(path: '/path/to/file.db', fileSystem: fileSystem),
        throwsA(isA<DbLoadError>()));
  });

  test('Db create throw when file already exists', () async {
    final fileSystem = MemoryFileSystem();
    final file = fileSystem.file('/path/to/file.db');
    await file.create(recursive: true);
    expect(
        Db.create(
            path: '/path/to/file.db', fileSystem: fileSystem, name: 'example'),
        throwsA(isA<DbLoadError>()));
  });
}
