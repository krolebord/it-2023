import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:unidb/providers/db.provider.dart';
import 'package:unidb/providers/db_tabs.provider.dart';
import 'package:unidb/tabs/new_table.tab.dart';
import 'package:unidb/tabs/table.tab.dart';

class DbInfoTab extends HookConsumerWidget {
  const DbInfoTab._({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final dbLoader = ref.read(dbLoaderProvider);
    final tabsController = ref.watch(tabsProvider);

    return Center(
      child: Card(
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Database: ${db.schema.name}'),
                Text('Last saved: ${db.lastSaved.toString()}'),
                Text('Size: ${db.size} bytes'),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),
                ...db.schema.tables.values.map(
                  (table) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          tabsController
                              .addTab(TableTab.create(tableName: table.name));
                          tabsController.selectedIndex =
                              tabsController.length - 1;
                        },
                        child: Text(table.name),
                      ),
                      IconButton(
                        onPressed: () async {
                          while (true) {
                            final index = tabsController.tabs.indexWhere(
                                (element) =>
                                    element.content is TableTab &&
                                    element.text == table.name);
                            if (index == -1) {
                              break;
                            }
                            tabsController.removeTab(index);
                          }
                          await Future.delayed(const Duration(milliseconds: 1));
                          db.removeTable(table.name);
                        },
                        icon: const Icon(Icons.delete),
                      )
                    ],
                  ),
                ),
                TextButton(
                    onPressed: () {
                      tabsController.addTab(AddTableTab.create());
                      tabsController.selectedIndex = tabsController.length - 1;
                    },
                    child: const Text('add table')),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),
                TextButton(onPressed: db.save, child: const Text('save db')),
                TextButton(
                    onPressed: dbLoader.closeDb, child: const Text('close db'))
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TabData create() {
    return TabData(
      text: 'db',
      closable: false,
      draggable: false,
      content: const DbInfoTab._(),
    );
  }
}
