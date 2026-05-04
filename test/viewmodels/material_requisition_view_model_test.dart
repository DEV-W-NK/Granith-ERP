import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/MaterialRequisitionViewModel.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';
import '../helpers/fake_material_requisition_service.dart';

void main() {
  group('MaterialRequisitionViewModel', () {
    MaterialRequisitionModel requisition({
      required String id,
      required RequisitionStatus status,
    }) {
      return MaterialRequisitionModel(
        id: id,
        projectId: 'project-1',
        projectName: 'Obra Centro',
        requesterName: 'Joao',
        requestDate: DateTime(2026, 5, 3),
        status: status,
        items: [RequisitionItem(itemName: 'Cimento', quantity: 10, unit: 'sc')],
        createdAt: DateTime(2026, 5, 3),
      );
    }

    test('completed agrega purchased, rejected e delivered', () async {
      final service = FakeMaterialRequisitionService(
        initialRequisitions: [
          requisition(id: '1', status: RequisitionStatus.pending),
          requisition(id: '2', status: RequisitionStatus.purchased),
          requisition(id: '3', status: RequisitionStatus.rejected),
          requisition(id: '4', status: RequisitionStatus.delivered),
        ],
      );
      final controller = MaterialRequisitionController(service: service);
      final viewModel = MaterialRequisitionViewModel(controller);

      viewModel.init();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.pendingCount, 1);
      expect(viewModel.completed, hasLength(3));

      await service.disposeController();
      viewModel.dispose();
      controller.dispose();
    });
  });
}
