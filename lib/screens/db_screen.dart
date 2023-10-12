import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:unidb/providers/db_tabs.provider.dart';

class DbScreen extends HookConsumerWidget {
  const DbScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabsController = ref.watch(tabsProvider);

    final theme = Theme.of(context);
    final tabsTheme = useMemoized(() {
      TabbedViewThemeData themeData = TabbedViewThemeData();
      const borderRadius = BorderRadius.all(Radius.circular(8.0));

      themeData.tabsArea
        ..border = const Border(
            top: BorderSide(color: Colors.transparent, width: 4),
            bottom: BorderSide(color: Colors.transparent, width: 4))
        ..buttonsGap = 4
        ..initialGap = 4
        ..middleGap = 4
        ..buttonsAreaDecoration =
            BoxDecoration(color: theme.hoverColor, borderRadius: borderRadius);

      themeData.tab
        ..padding = const EdgeInsets.fromLTRB(12, 6, 12, 6)
        ..buttonsOffset = 8
        ..closeIcon = IconProvider.data(Icons.close)
        ..normalButtonColor = theme.colorScheme.onSecondaryContainer
        ..hoverButtonColor = theme.colorScheme.onSecondaryContainer
        ..disabledButtonColor = theme.colorScheme.onSecondaryContainer
        ..decoration =
            BoxDecoration(color: theme.hoverColor, borderRadius: borderRadius)
        ..selectedStatus.decoration = BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: borderRadius)
        ..textStyle = theme.textTheme.bodyMedium!
            .copyWith(color: theme.colorScheme.onSecondaryContainer)
        ..highlightedStatus.decoration =
            BoxDecoration(color: theme.focusColor, borderRadius: borderRadius);

      themeData.contentArea.decoration = BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)));
      return themeData;
    });

    return Scaffold(
      body: TabbedViewTheme(
        data: tabsTheme,
        child: TabbedView(
          controller: tabsController,
        ),
      ),
    );
  }
}
