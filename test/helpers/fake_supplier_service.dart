import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/supplier_service.dart';

class FakeSupplierService extends SupplierService {
  FakeSupplierService({List<Supplier>? initialSuppliers})
    : _suppliers = List<Supplier>.from(initialSuppliers ?? const <Supplier>[]);

  final List<Supplier> _suppliers;
  Object? getSuppliersError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Object? toggleError;
  Supplier? lastCreatedSupplier;
  Supplier? lastUpdatedSupplier;
  String? lastDeletedId;
  String? lastToggledId;
  bool? lastToggledStatus;
  String createdId = 'supplier-created';

  @override
  Future<List<Supplier>> getSuppliers() async {
    if (getSuppliersError != null) {
      throw getSuppliersError!;
    }
    return List<Supplier>.from(_suppliers);
  }

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    if (createError != null) {
      throw createError!;
    }

    lastCreatedSupplier = supplier;
    final created = supplier.copyWith(id: createdId);
    _suppliers.add(created);
    return created;
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    if (updateError != null) {
      throw updateError!;
    }

    lastUpdatedSupplier = supplier;
    final index = _suppliers.indexWhere((entry) => entry.id == supplier.id);
    if (index >= 0) {
      _suppliers[index] = supplier;
    }
    return supplier;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    if (deleteError != null) {
      throw deleteError!;
    }

    lastDeletedId = id;
    _suppliers.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<Supplier> toggleSupplierStatus(String id, bool isActive) async {
    if (toggleError != null) {
      throw toggleError!;
    }

    lastToggledId = id;
    lastToggledStatus = isActive;

    final index = _suppliers.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      throw Exception('Fornecedor nao encontrado');
    }

    final updated = _suppliers[index].copyWith(isActive: isActive);
    _suppliers[index] = updated;
    return updated;
  }
}
