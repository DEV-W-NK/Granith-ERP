import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/constants/supplier_constants.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/models/supplier_model.dart';

import '../helpers/fake_supplier_service.dart';

void main() {
  group('SupplierController', () {
    Supplier supplier({
      required String id,
      required String name,
      required String cnpj,
      bool isActive = true,
    }) {
      return Supplier(
        id: id,
        name: name,
        cnpj: cnpj,
        isActive: isActive,
        createdAt: DateTime(2026, 5, 3),
        updatedAt: DateTime(2026, 5, 3),
      );
    }

    test('loadSuppliers, busca e filtro combinam corretamente', () async {
      final service = FakeSupplierService(
        initialSuppliers: [
          supplier(id: '1', name: 'Beta', cnpj: '11222333000181'),
          supplier(
            id: '2',
            name: 'Alfa',
            cnpj: '19131243000197',
            isActive: false,
          ),
        ],
      );
      final controller = SupplierController(service);

      await controller.loadSuppliers();
      controller.updateSearchQuery('11.222');
      controller.updateFilter(SupplierConstants.filterActive);

      expect(controller.suppliers, hasLength(2));
      expect(controller.filteredSuppliers.single.id, '1');
      expect(controller.hasActiveFilters, isTrue);
    });

    test('create, update, delete e toggle atualizam estado local', () async {
      final service = FakeSupplierService(
        initialSuppliers: [
          supplier(id: '1', name: 'Alfa', cnpj: '19131243000197'),
        ],
      );
      final controller = SupplierController(service);
      await controller.loadSuppliers();

      await controller.createSupplier(
        supplier(id: '', name: 'Beta', cnpj: '11222333000181'),
      );
      await controller.updateSupplier(
        supplier(id: '1', name: 'Alfa Prime', cnpj: '19131243000197'),
      );
      await controller.toggleSupplierStatus('1', false);
      await controller.deleteSupplier('1');

      expect(service.lastCreatedSupplier?.name, 'Beta');
      expect(service.lastUpdatedSupplier?.name, 'Alfa Prime');
      expect(service.lastToggledStatus, isFalse);
      expect(service.lastDeletedId, '1');
    });

    test('validacoes, formatacao e exportacao cobrem regras de formulario', () async {
      final controller = SupplierController(
        FakeSupplierService(
          initialSuppliers: [
            supplier(id: '1', name: 'Fornecedor A', cnpj: '19131243000197'),
          ],
        ),
      );
      await controller.loadSuppliers();

      expect(controller.validateSupplierName('A'), contains('pelo menos'));
      expect(
        controller.validateSupplierCnpj('19.131.243/0001-97'),
        SupplierConstants.errorCnpjAlreadyExists,
      );
      expect(controller.validateSupplierCnpj('11.111.111/1111-11'), isNotNull);
      expect(
        controller.formatCnpj('19131243000197'),
        '19.131.243/0001-97',
      );
      expect(controller.cleanCnpj('19.131.243/0001-97'), '19131243000197');

      await controller.exportSuppliers('csv');
      expect(controller.hasError, isFalse);

      await controller.exportSuppliers('xml');
      expect(controller.errorMessage, contains('suportado'));
    });

    test('loadSuppliers expõe erro amigavel quando service falha', () async {
      final service = FakeSupplierService()..getSuppliersError = Exception('offline');
      final controller = SupplierController(service);

      await controller.loadSuppliers();

      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('Erro ao carregar fornecedores'));
    });
  });
}
