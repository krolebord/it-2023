import 'dart:convert';
import 'dart:typed_data';
import 'package:davi/davi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:unidb/db/columns.dart';
import 'package:unidb/providers/db.provider.dart';

class TableTab extends HookConsumerWidget {
  final String tableName;

  const TableTab._({Key? key, required this.tableName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(tableProvider(tableName));
    final allColumns = table.table.columns;

    final initialColumnNames = useMemoized(
      () => allColumns.map((col) => col.name).toSet(),
      [],
    );
    final selectedColumnNames = useState(initialColumnNames);
    final selectedColumns = useMemoized(
      () => allColumns
          .where((col) => selectedColumnNames.value.contains(col.name))
          .toList(),
      [selectedColumnNames.value],
    );

    final colNameToIndex = useMemoized(
      () => Map.fromEntries(
        allColumns.asMap().entries.map((e) => MapEntry(e.value.name, e.key)),
      ),
      [],
    );

    final rootContext = useContext();

    final model = DaviModel<List<Object>>(
      columns: [
        DaviColumn(
          resizable: false,
          sortable: false,
          width: 140,
          cellAlignment: Alignment.center,
          headerPadding: const EdgeInsets.only(left: 10),
          leading: IconButton(
            onPressed: () async {
              final newSelected = await ColumnSelectDialog.show(
                context: rootContext,
                columns: table.table.columns,
                selectedColumnNames: selectedColumnNames.value,
              );

              if (newSelected == null) {
                return;
              }

              selectedColumnNames.value = newSelected;
            },
            icon: const Icon(Icons.settings),
            color: Colors.white60,
            splashRadius: 16,
            padding: EdgeInsets.zero,
          ),
          cellBuilder: (context, row) => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  final editedRow = await RowEditDialog.show(
                    context: rootContext,
                    columns: allColumns,
                    row: row.data,
                  );

                  if (editedRow == null) {
                    return;
                  }

                  table.updateRow(row.data[0] as int, editedRow);
                },
                icon: const Icon(Icons.edit),
                color: Colors.white60,
                splashRadius: 16,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () {
                  table.removeRow(row.data[0] as int);
                },
                icon: const Icon(Icons.delete),
                color: Colors.white60,
                splashRadius: 16,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () {
                  table.duplicateRow(row.data[0] as int);
                },
                icon: const Icon(Icons.copy),
                color: Colors.white60,
                splashRadius: 16,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        ...selectedColumns.map(
            (col) => mapDaviColumn(context, col, colNameToIndex[col.name]!))
      ],
      rows: table.table.rows,
    );

    return Davi(
      model,
      lastRowWidget: InkWell(
        onTap: () async {
          final row =
              await RowEditDialog.show(context: context, columns: allColumns);

          if (row == null) {
            return;
          }

          table.addRow(row);
        },
        child: const Center(child: Text('Add row')),
      ),
    );
  }

  static TabData create({required String tableName}) {
    return TabData(
      text: tableName,
      content: TableTab._(tableName: tableName),
      keepAlive: true,
    );
  }
}

class RowEditDialog extends HookWidget {
  final List<DbColumn> columns;
  late final Map<String, Object> initialValue;

  RowEditDialog({
    Key? key,
    required this.columns,
    Map<String, Object>? initialValue,
  }) : super(key: key) {
    this.initialValue = initialValue ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormBuilderState>());

    return Dialog(
      child: FormBuilder(
        key: formKey,
        initialValue: initialValue,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ...columns.expand(
                  (column) => [
                    mapCellField(column),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final form = formKey.currentState;
                    if (form == null || !form.saveAndValidate()) {
                      return;
                    }

                    final Map<String, Object> value =
                        form.value.cast<String, Object>();
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Save'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<Map<String, Object>?> show({
    required BuildContext context,
    required List<DbColumn> columns,
    List<Object>? row,
  }) async {
    final columnsWithoutId = columns.skip(1).toList();

    final initialValue = row == null
        ? null
        : Map.fromEntries(columns.asMap().entries.map((e) {
            final columnName = e.value.name;
            final cellValue = row[e.key];
            if (cellValue is IntegerRange?) {
              return MapEntry(columnName, cellValue);
            }
            if (cellValue is TextFile) {
              final bytes = Uint8List.fromList(utf8.encode(cellValue.content));
              return MapEntry(columnName, [
                PlatformFile(
                    name: cellValue.path, size: bytes.length, bytes: bytes)
              ]);
            }
            return MapEntry(columnName, cellValue.toString());
          }));
    final savedRow = await showDialog<Map<String, Object>?>(
      context: context,
      builder: (context) => RowEditDialog(
        columns: columnsWithoutId,
        initialValue: initialValue,
      ),
    );

    if (savedRow == null ||
        columnsWithoutId.any((col) => savedRow[col.name] == null)) {
      return null;
    }

    return savedRow;
  }
}

class ColumnSelectDialog extends HookWidget {
  final List<DbColumn> columns;
  late final Map<String, bool> initialValue;

  ColumnSelectDialog({
    Key? key,
    required this.columns,
    Map<String, bool>? initialValue,
  }) : super(key: key) {
    this.initialValue = initialValue ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormBuilderState>());
    return Dialog(
      child: FormBuilder(
        key: formKey,
        initialValue: initialValue,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ...columns.map(
                  (col) => FormBuilderCheckbox(
                      name: col.name, title: Text(col.name)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final form = formKey.currentState;
                    if (form == null || !form.saveAndValidate()) {
                      return;
                    }

                    final Map<String, bool> value =
                        form.value.cast<String, bool>();
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Select'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<Set<String>?> show({
    required BuildContext context,
    required List<DbColumn> columns,
    required Set<String> selectedColumnNames,
  }) async {
    final initialValue = Map.fromEntries(columns.map(
        (col) => MapEntry(col.name, selectedColumnNames.contains(col.name))));
    final newSelectedCols = await showDialog<Map<String, bool>?>(
      context: context,
      builder: (context) => ColumnSelectDialog(
        columns: columns,
        initialValue: initialValue,
      ),
    );

    if (newSelectedCols == null) {
      return null;
    }

    return newSelectedCols.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
  }
}

DaviColumn<List<Object>> mapDaviColumn(
  BuildContext rootContext,
  DbColumn column,
  int index,
) {
  switch (column.type) {
    case ColumnType.integer:
      return DaviColumn<List<Object>>(
        name: column.name,
        intValue: (row) => row[index] as int,
      );
    case ColumnType.real:
      return DaviColumn<List<Object>>(
        name: column.name,
        doubleValue: (row) => row[index] as double,
      );
    case ColumnType.char:
      return DaviColumn<List<Object>>(
        name: column.name,
        intValue: (row) => row[index] as int,
      );
    case ColumnType.string:
      return DaviColumn<List<Object>>(
        name: column.name,
        stringValue: (row) => row[index] as String,
      );
    case ColumnType.intRange:
      return DaviColumn<List<Object>>(
        name: column.name,
        stringValue: (row) {
          final range = row[index] as IntegerRange;
          return '(${range.min}, ${range.max})';
        },
      );
    case ColumnType.txtFile:
      return DaviColumn<List<Object>>(
        name: column.name,
        objectValue: (row) => row[index] as TextFile,
        cellPadding: EdgeInsets.zero,
        cellBuilder: (context, row) {
          final file = row.data[index] as TextFile;
          return InkWell(
            onTap: () {
              showDialog(
                context: rootContext,
                builder: (context) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(file.path,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            file.content,
                            textAlign: TextAlign.start,
                          ),
                        )
                      ],
                    )),
                  ),
                ),
              );
            },
            child: Center(
              child: Text(file.path),
            ),
          );
        },
      );
  }
}

Widget mapCellField(DbColumn column) {
  switch (column.type) {
    case ColumnType.integer:
      return FormBuilderTextField(
        name: column.name,
        decoration: InputDecoration(labelText: column.name),
        valueTransformer: (value) => int.tryParse(value ?? '0'),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.integer(),
        ]),
      );
    case ColumnType.real:
      return FormBuilderTextField(
        name: column.name,
        decoration: InputDecoration(labelText: column.name),
        valueTransformer: (value) => double.tryParse(value ?? '0'),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.numeric(),
        ]),
      );
    case ColumnType.char:
      return FormBuilderTextField(
        name: column.name,
        decoration: InputDecoration(labelText: column.name),
        valueTransformer: (value) => int.tryParse(value ?? '0'),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.integer(),
          FormBuilderValidators.min(0),
          FormBuilderValidators.max(255),
        ]),
      );
    case ColumnType.string:
      return FormBuilderTextField(
        name: column.name,
        decoration: InputDecoration(labelText: column.name),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
        ]),
      );
    case ColumnType.intRange:
      return FormBuilderField<IntegerRange>(
        name: column.name,
        validator: (value) {
          if (value == null || value.min > value.max) {
            return 'Invalid range';
          }
          return null;
        },
        builder: (field) => HookBuilder(builder: (context) {
          final minController =
              useTextEditingController(text: field.value?.min.toString());
          final maxController =
              useTextEditingController(text: field.value?.max.toString());
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FormBuilderTextField(
                  name: '${column.name}:min',
                  controller: minController,
                  decoration: const InputDecoration(labelText: 'Min'),
                  valueTransformer: (value) => int.tryParse(value ?? '0'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                  onChanged: (_) => field.didChange(IntegerRange(
                    min: int.tryParse(minController.text) ?? 0,
                    max: int.tryParse(maxController.text) ?? 0,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FormBuilderTextField(
                  name: '${column.name}:max',
                  controller: maxController,
                  decoration: const InputDecoration(labelText: 'Max'),
                  valueTransformer: (value) => int.tryParse(value ?? '0'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                  onChanged: (_) => field.didChange(IntegerRange(
                    min: int.tryParse(minController.text) ?? 0,
                    max: int.tryParse(maxController.text) ?? 0,
                  )),
                ),
              ),
            ],
          );
        }),
      );
    case ColumnType.txtFile:
      return FormBuilderFilePicker(
        name: column.name,
        decoration: InputDecoration(labelText: column.name),
        maxFiles: 1,
        allowMultiple: false,
        allowedExtensions: const ['txt'],
        typeSelectors: const [
          TypeSelector(type: FileType.custom, selector: Icon(Icons.add_circle))
        ],
        withData: true,
        previewImages: false,
        valueTransformer: (value) {
          final file = value?[0];

          if (file == null || file.extension != 'txt') {
            return null;
          }
          final content = utf8.decode(file.bytes!);
          return TextFile(path: file.name, content: content);
        },
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
        ]),
      );
  }
}
