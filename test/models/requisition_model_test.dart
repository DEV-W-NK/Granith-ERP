import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/requisition_model.dart';

void main() {
  group('MaterialRequisitionModel', () {
    test('fromMap parseia itens, status e metadados de aprovacao', () {
      final now = DateTime(2026, 5, 3, 15);
      final requisition = MaterialRequisitionModel.fromMap({
        'projectId': 'project-1',
        'projectName': 'Obra Centro',
        'requesterName': 'Joao',
        'requestDate': now.toIso8601String(),
        'status': 'approved',
        'items': [
          {'itemName': 'Cimento', 'quantity': 12, 'unit': 'sc'},
          {'itemName': 'Brita', 'quantity': 4, 'unit': 'm3'},
        ],
        'priority': 'Alta',
        'approvedBy': 'manager-1',
        'approvedByName': 'Maria',
        'approvedAt': now.toIso8601String(),
        'purchaseId': 'purchase-1',
        'createdAt': now.toIso8601String(),
      }, 'req-1');

      expect(requisition.id, 'req-1');
      expect(requisition.status, RequisitionStatus.approved);
      expect(requisition.itemCount, 2);
      expect(requisition.totalQuantity, 16);
      expect(requisition.purchaseId, 'purchase-1');
      expect(requisition.itemsSummary, 'Cimento e mais 1');
    });

    test('copyWith permite avancar status mantendo demais dados', () {
      final requisition = MaterialRequisitionModel(
        id: 'req-1',
        projectId: 'project-1',
        projectName: 'Obra Centro',
        requesterName: 'Joao',
        requestDate: DateTime(2026, 5, 3),
        status: RequisitionStatus.pending,
        items: [RequisitionItem(itemName: 'Areia', quantity: 3, unit: 'm3')],
        createdAt: DateTime(2026, 5, 3),
      );

      final approved = requisition.copyWith(
        status: RequisitionStatus.approved,
        approvedByName: 'Maria',
      );

      expect(approved.status, RequisitionStatus.approved);
      expect(approved.approvedByName, 'Maria');
      expect(approved.projectName, 'Obra Centro');
    });
  });
}
