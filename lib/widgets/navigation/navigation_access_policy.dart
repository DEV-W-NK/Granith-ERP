import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

abstract final class NavigationAccessPolicy {
  static List<NavigationModule> availableModules(
    Iterable<NavigationModule> modules,
    UserModel? user,
  ) {
    return modules
        .where((module) => canAccess(module.index, user))
        .toList(growable: false);
  }

  static bool canAccess(int moduleIndex, UserModel? user) {
    if (moduleIndex == 0) return true;
    if (user == null) return false;
    if (user.isAdmin) return true;

    final permissions = user.permissions.toSet();
    if (permissions.contains('admin')) return true;
    if (permissions.isEmpty) return false;

    return switch (moduleIndex) {
      1 => _hasAny(permissions, const [
        'projects.read',
        'projects.write',
        'obras',
      ]),
      2 => _hasAny(permissions, const [
        'projects.read',
        'projects.write',
        'obras',
        'medicoes',
      ]),
      3 => _hasAny(permissions, const [
        'projects.read',
        'projects.write',
        'obras',
        'diario',
        'mobile.daily_logs.write',
      ]),
      4 => _hasAny(permissions, const [
        'projects.read',
        'projects.write',
        'obras',
        'suprimentos',
        'compras',
        'inventory.read',
        'inventory.write',
        'mobile.materials.request',
      ]),
      5 || 6 || 7 => _hasAny(permissions, const [
        'people.manage',
        'people.salary.read',
        'rh',
        'mobile.team.manage',
      ]),
      8 || 9 => _hasAny(permissions, const ['budgets.read', 'budgets.write']),
      10 => _hasAny(permissions, const ['suprimentos', 'compras']),
      11 || 14 => _hasAny(permissions, const [
        'inventory.read',
        'inventory.write',
        'estoque',
        'suprimentos',
        'compras',
      ]),
      12 => _hasAny(permissions, const [
        'purchases.approve',
        'purchases.consolidate',
        'compras',
        'suprimentos',
      ]),
      13 => _hasAny(permissions, const [
        'purchases.consolidate',
        'compras',
        'suprimentos',
        'mobile.fuel_logs.write',
      ]),
      15 => _hasAny(permissions, const [
        'mobile.fuel_logs.write',
        'suprimentos',
        'compras',
      ]),
      16 => _hasAny(permissions, const [
        'time_clock.read',
        'time_clock.manage',
        'mobile.work_hours.manual',
        'projects.read',
        'projects.write',
        'obras',
      ]),
      17 || 28 => _hasAny(permissions, const [
        'financial.read',
        'financial.write',
        'financeiro',
      ]),
      18 => _hasAny(permissions, const [
        'time_clock.read',
        'time_clock.manage',
        'financial.read',
        'financial.write',
        'financeiro',
      ]),
      19 => _hasAny(permissions, const [
        'purchase_finance.read',
        'purchase_finance.write',
        'purchases.consolidate',
        'financial.read',
        'financial.write',
        'financeiro',
        'compras',
      ]),
      20 => _hasAny(permissions, const [
        'financial.read',
        'financial.write',
        'financeiro',
        'relatorios',
      ]),
      21 => permissions.contains('access.manage'),
      22 => _hasAny(permissions, const [
        'projects.read',
        'projects.write',
        'obras',
        'diario',
        'medicoes',
      ]),
      23 => _hasAny(permissions, const [
        'people.manage',
        'people.salary.read',
        'rh',
      ]),
      24 => _hasAny(permissions, const ['budgets.read', 'budgets.write']),
      25 => _hasAny(permissions, const [
        'inventory.read',
        'inventory.write',
        'purchases.approve',
        'purchases.consolidate',
        'estoque',
        'suprimentos',
        'compras',
      ]),
      26 => _hasAny(permissions, const [
        'access.manage',
        'settings.manage',
        'financial.read',
        'financial.write',
        'financeiro',
      ]),
      27 => _hasAny(permissions, const ['settings.manage', 'billing.manage']),
      29 => true,
      _ => false,
    };
  }

  static bool _hasAny(Set<String> permissions, List<String> expected) {
    return expected.any(permissions.contains);
  }
}
