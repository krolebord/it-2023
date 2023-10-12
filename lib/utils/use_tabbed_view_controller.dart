import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tabbed_view/tabbed_view.dart';

TabbedViewController useTabbedViewController(List<TabData> tabs) {
  final controller = useMemoized(() => TabbedViewController(tabs), [tabs]);
  useEffect(() => () => controller.dispose(), [controller]);
  return controller;
}
