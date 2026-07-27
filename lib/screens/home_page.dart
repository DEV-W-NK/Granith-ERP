import 'package:flutter/material.dart';
import 'package:project_granith/widgets/home_page/home_page_view.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.modules = const <NavigationModule>[],
    this.onModuleSelected,
  });

  final List<NavigationModule> modules;
  final ValueChanged<int>? onModuleSelected;

  @override
  Widget build(BuildContext context) {
    return HomePageView(modules: modules, onModuleSelected: onModuleSelected);
  }
}
