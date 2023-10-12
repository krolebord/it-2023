import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:unidb/providers/db.provider.dart';
import 'package:unidb/screens/db_screen.dart';
import 'package:unidb/screens/select_db.screen.dart';

final _key = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final dbLoader = ref.watch(dbLoaderProvider);

  return GoRouter(
    navigatorKey: _key,
    debugLogDiagnostics: true,
    initialLocation: '/pickDb',
    refreshListenable: dbLoader,
    routes: [
      GoRoute(
        name: 'pickDb',
        path: '/pickDb',
        builder: (context, state) => const SelectDbScreen(),
      ),
      GoRoute(
        name: '/',
        path: '/',
        builder: (context, state) => ProviderScope(
          overrides: [
            dbProvider.overrideWith((ref) => DbNotifier(dbLoader.db!)),
          ],
          child: const DbScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final isConfigSet = dbLoader.db != null;

      if (state.fullPath == '/pickDb') {
        return isConfigSet ? '/' : null;
      }

      return isConfigSet ? null : '/pickDb';
    },
  );
});
