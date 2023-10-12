import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:unidb/db/columns.dart';
import 'package:unidb/providers/db.provider.dart';
import 'package:unidb/providers/db_tabs.provider.dart';

class AddTableTab extends HookConsumerWidget {
  final GlobalKey<FormBuilderState> formKey;

  const AddTableTab._({Key? key, required this.formKey}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final tabs = ref.watch(tabsProvider);
    final columns = useState(<int>[0]);

    return Center(
      child: Card(
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FormBuilder(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FormBuilderTextField(
                      name: 'name',
                      decoration:
                          const InputDecoration(labelText: 'Table name'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    ...columns.value.expand(
                      (id) => [
                        Row(
                          key: ValueKey(id),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 260,
                              child: FormBuilderTextField(
                                key: ValueKey('columns:$id:name'),
                                name: 'columns:$id:name',
                                decoration: const InputDecoration(
                                    labelText: 'Column name'),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: FormBuilderDropdown(
                                key: ValueKey('columns:$id:type'),
                                name: 'columns:$id:type',
                                decoration: const InputDecoration(
                                    labelText: 'Column type'),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                                items: ColumnType.values
                                    .map((e) => DropdownMenuItem(
                                        value: e,
                                        child:
                                            Text(e.toString().split('.').last)))
                                    .toList(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: IconButton.outlined(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  columns.value.remove(id);
                                  columns.value = [...columns.value];
                                  formKey.currentState?.patchValue({
                                    'columns:$id:name': null,
                                    'columns:$id:type': null,
                                  });
                                },
                                icon: const Icon(Icons.remove),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                        columns.value.add((columns.value.lastOrNull ?? -1) + 1);
                        columns.value = [...columns.value];
                      },
                      child: const Text('Add column'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SizedBox(
                        width: 200,
                        child: FilledButton(
                          onPressed: () {
                            final form = formKey.currentState;
                            if (form == null || !form.saveAndValidate()) {
                              return;
                            }

                            final name = form.value['name'] as String;
                            final tableColumns = columns.value.map((id) => (
                                  name:
                                      form.value['columns:$id:name'] as String,
                                  type: form.value['columns:$id:type']
                                      as ColumnType,
                                ));

                            db.addTable(name: name, columns: tableColumns);
                            tabs.removeTab(tabs.selectedIndex!);
                          },
                          child: const Text('Create table'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TabData create() {
    return TabData(
      text: 'new table',
      content: AddTableTab._(formKey: GlobalKey<FormBuilderState>()),
      keepAlive: true,
    );
  }
}
