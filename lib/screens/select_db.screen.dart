import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:unidb/providers/db.provider.dart';

class SelectDbScreen extends HookConsumerWidget {
  const SelectDbScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loader = ref.watch(dbLoaderProvider);
    final dbNameController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a database'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: loader.openDb,
                child: const Text('Open db'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Or'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: dbNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Database name',
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () async {
                  if (dbNameController.text.isEmpty) {
                    return;
                  }
                  await loader.createDb(name: dbNameController.text);
                },
                child: const Text('Create new db'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
