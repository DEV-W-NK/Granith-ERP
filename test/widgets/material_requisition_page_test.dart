import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/viewmodels/materialrequisitionviewmodel.dart';
import 'package:project_granith/widgets/materialrequisition/material_requisition_page_page_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_material_requisition_service.dart';

void main() {
  group('MaterialRequisitionPageView', () {
    testWidgets('exibe resumo operacional e cards de requisicao', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Subject(
          requisitions: [
            _requisition(
              id: 'req-1',
              projectName: 'Obra Alpha',
              requesterName: 'Marina',
              status: RequisitionStatus.pending,
              priority: 'Alta',
              items: [
                RequisitionItem(
                  itemName: 'Cimento CP II',
                  quantity: 20,
                  unit: 'sc',
                ),
              ],
            ),
            _requisition(
              id: 'req-2',
              projectName: 'Obra Beta',
              requesterName: 'Carlos',
              status: RequisitionStatus.purchased,
              priority: 'Media',
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Requisições de Materiais'), findsOneWidget);
      expect(find.text('2 de 2'), findsOneWidget);
      expect(find.text('Pendentes (1)'), findsOneWidget);
      expect(find.text('Obra Alpha'), findsOneWidget);
      expect(find.text('Prioridade Alta'), findsOneWidget);
      expect(find.text('Orcar fornecedores'), findsAtLeastNWidgets(1));
    });

    testWidgets('filtra requisicoes por item e atualiza contadores', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Subject(
          requisitions: [
            _requisition(
              id: 'req-1',
              projectName: 'Obra Hidraulica',
              requesterName: 'Marina',
              status: RequisitionStatus.pending,
              items: [
                RequisitionItem(itemName: 'Tubo PVC', quantity: 12, unit: 'un'),
              ],
            ),
            _requisition(
              id: 'req-2',
              projectName: 'Obra Eletrica',
              requesterName: 'Carlos',
              status: RequisitionStatus.approved,
              items: [
                RequisitionItem(itemName: 'Disjuntor', quantity: 4, unit: 'un'),
              ],
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'pvc');
      await tester.pumpAndSettle();

      expect(find.text('Todas (1)'), findsOneWidget);
      expect(find.text('Obra Hidraulica'), findsOneWidget);
      expect(find.text('Obra Eletrica'), findsNothing);
    });

    testWidgets('mantem filtros sem overflow em viewport estreito', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _Subject(
          requisitions: [
            _requisition(
              id: 'req-1',
              projectName: 'Obra Compacta',
              requesterName: 'Marina',
              status: RequisitionStatus.pending,
              priority: 'Alta',
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(DropdownButtonHideUnderline), findsOneWidget);
      expect(find.text('1 de 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _Subject extends StatefulWidget {
  final List<MaterialRequisitionModel> requisitions;

  const _Subject({required this.requisitions});

  @override
  State<_Subject> createState() => _SubjectState();
}

class _SubjectState extends State<_Subject> {
  late final FakeMaterialRequisitionService service;
  late final MaterialRequisitionController controller;
  late final MaterialRequisitionViewModel viewModel;

  @override
  void initState() {
    super.initState();
    service = FakeMaterialRequisitionService(
      initialRequisitions: widget.requisitions,
    );
    controller = MaterialRequisitionController(service: service);
    viewModel = MaterialRequisitionViewModel(controller);
  }

  @override
  void dispose() {
    viewModel.dispose();
    controller.dispose();
    service.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MaterialRequisitionViewModel>.value(
      value: viewModel,
      child: const MaterialApp(home: MaterialRequisitionPageView()),
    );
  }
}

MaterialRequisitionModel _requisition({
  required String id,
  required String projectName,
  required String requesterName,
  required RequisitionStatus status,
  String priority = 'Media',
  List<RequisitionItem>? items,
}) {
  return MaterialRequisitionModel(
    id: id,
    projectId: 'project-$id',
    projectName: projectName,
    requesterName: requesterName,
    requesterSector: 'Engenharia',
    requestDate: DateTime(2026, 5, 10),
    status: status,
    items:
        items ??
        [RequisitionItem(itemName: 'Areia media', quantity: 3, unit: 'm3')],
    priority: priority,
    createdAt: DateTime(2026, 5, 10),
  );
}
