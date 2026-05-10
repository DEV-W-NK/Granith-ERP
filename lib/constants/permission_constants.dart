abstract final class PermissionCodes {
  static const peopleSalaryRead = 'people.salary.read';
  static const purchasesApprove = 'purchases.approve';
  static const purchasesConsolidate = 'purchases.consolidate';
  static const purchaseFinanceRead = 'purchase_finance.read';
  static const purchaseFinanceWrite = 'purchase_finance.write';
  static const aiMonitor = 'ai.monitor';
  static const aiUsageRead = 'ai.usage.read';
  static const aiPricingManage = 'ai.pricing.manage';

  static bool canViewPeopleSalary({
    required bool isAdmin,
    required Iterable<String> permissions,
  }) {
    final permissionSet = permissions.toSet();
    return isAdmin ||
        permissionSet.contains(peopleSalaryRead) ||
        permissionSet.contains('admin');
  }

  static bool canApprovePurchases({
    required bool isAdmin,
    required Iterable<String> permissions,
    String? sector,
  }) {
    final permissionSet = permissions.toSet();
    if (isAdmin ||
        permissionSet.contains('admin') ||
        permissionSet.contains(purchasesApprove)) {
      return true;
    }

    final normalizedSector = normalizePermissionSegment(sector ?? '');
    return normalizedSector.isNotEmpty &&
        permissionSet.contains('$purchasesApprove.$normalizedSector');
  }

  static bool canConsolidatePurchases({
    required bool isAdmin,
    required Iterable<String> permissions,
  }) {
    final permissionSet = permissions.toSet();
    return isAdmin ||
        permissionSet.contains('admin') ||
        permissionSet.contains(purchasesConsolidate) ||
        permissionSet.contains('compras');
  }

  static bool canViewPurchaseFinance({
    required bool isAdmin,
    required Iterable<String> permissions,
  }) {
    final permissionSet = permissions.toSet();
    return isAdmin ||
        permissionSet.contains('admin') ||
        permissionSet.contains(purchaseFinanceRead) ||
        permissionSet.contains(purchaseFinanceWrite) ||
        permissionSet.contains('financial.read') ||
        permissionSet.contains('financial.write') ||
        permissionSet.contains('financeiro') ||
        permissionSet.contains(purchasesConsolidate) ||
        permissionSet.contains('compras');
  }

  static bool canManagePurchaseFinance({
    required bool isAdmin,
    required Iterable<String> permissions,
  }) {
    final permissionSet = permissions.toSet();
    return isAdmin ||
        permissionSet.contains('admin') ||
        permissionSet.contains(purchaseFinanceWrite) ||
        permissionSet.contains('financial.write') ||
        permissionSet.contains('financeiro');
  }

  static bool canViewFinancial({
    required bool isAdmin,
    required Iterable<String> permissions,
  }) {
    final permissionSet = permissions.toSet();
    return isAdmin ||
        permissionSet.contains('admin') ||
        permissionSet.contains('financial.read') ||
        permissionSet.contains('financial.write') ||
        permissionSet.contains('financeiro');
  }

  static String normalizePermissionSegment(String value) {
    return _removeDiacritics(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
  }

  static String _removeDiacritics(String value) {
    const from = 'áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ';
    const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    var result = value;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }
}
