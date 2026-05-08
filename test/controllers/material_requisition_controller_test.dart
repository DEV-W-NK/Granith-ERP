import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import '../helpers/fake_material_requisition_service.dart';

void main() {
  group('MaterialRequisitionController', () {
    MaterialRequisitionModel requisition({
      required String id,
      required RequisitionStatus status,
      String priority = 'Media',
    }) {
      return MaterialRequisitionModel(
        id: id,
        projectId: 'project-1',
        projectName: 'Obra Centro',
        requesterName: 'Joao',
        requestDate: DateTime(2026, 5, 3),
        status: status,
        items: [RequisitionItem(itemName: 'Cimento', quantity: 10, unit: 'sc')],
        priority: priority,
        createdAt: DateTime(2026, 5, 3),
      );
    }

    final supplier = Supplier(
      id: 'supplier-1',
      name: 'Fornecedor Alpha',
      cnpj: '12345678000199',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('init consome stream e expõe filtros derivados', () async {
      final service = FakeMaterialRequisitionService(
        initialRequisitions: [
          requisition(
            id: 'req-1',
            status: RequisitionStatus.pending,
            priority: 'Alta',
          ),
          requisition(id: 'req-2', status: RequisitionStatus.approved),
          requisition(id: 'req-3', status: RequisitionStatus.rejected),
        ],
      );
      final controller = MaterialRequisitionController(service: service);

      controller.init();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.requisitions, hasLength(3));
      expect(controller.pending, hasLength(1));
      expect(controller.approved, hasLength(1));
      expect(controller.highPriority, hasLength(1));
      expect(controller.pendingCount, 1);

      await service.disposeController();
      controller.dispose();
    });

    test('approve/reject/convert delegam para o service', () async {
      final service = FakeMaterialRequisitionService();
      final controller = MaterialRequisitionController(service: service);
      final req = requisition(id: 'req-1', status: RequisitionStatus.approved);

      await controller.approve(
        requisition: req,
        approvedBy: 'manager-1',
        approvedByName: 'Maria',
      );
      await controller.reject(
        requisition: req,
        rejectedBy: 'manager-2',
        rejectedByName: 'Paulo',
        reason: 'Ajustar quantitativo',
      );
      final purchaseIds = await controller.convertToPurchase(
        requisition: req,
        supplier: supplier,
        createdBy: 'buyer-1',
        itemPrices: const {'Cimento': 1500},
        approvalSector: 'Engenharia',
      );

      expect(service.lastApproved, req);
      expect(service.lastRejected, req);
      expect(service.lastConvertPayload?['createdBy'], 'buyer-1');
      expect(service.lastConvertPayload?['approvalSector'], 'Engenharia');
      expect(purchaseIds, ['purchase-1']);

      await service.disposeController();
      controller.dispose();
    });

    test('init expõe erro amigável quando stream falha', () async {
      final service =
          FakeMaterialRequisitionService()..streamError = Exception('offline');
      final controller = MaterialRequisitionController(service: service);

      controller.init();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.error, contains('Exception: offline'));

      await service.disposeController();
      controller.dispose();
    });
  });
}
