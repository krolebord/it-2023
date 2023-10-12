import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:unidb/providers/db.provider.dart';
import 'package:unidb/tabs/db_info.tab.dart';

final tabsProvider = Provider((ref) {
  ref.watch(dbLoaderProvider);
  return TabbedViewController([
    DbInfoTab.create(),
  ]);
}, dependencies: [dbLoaderProvider]);
