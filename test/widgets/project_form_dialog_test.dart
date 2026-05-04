import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/widgets/projects/project_form_dialog.dart';

import '../helpers/fake_client_account_service.dart';
import '../helpers/fake_service_projetos.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('ProjectFormDialog', () {
    testWidgets('valida campos obrigatorios antes de avancar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildHarness(
          ProjectFormDialog(
            onSave: (_) {},
            projectService: FakeServiceProjetos(),
            clientAccountService: FakeClientAccountService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('obrigat'), findsNWidgets(2));
    });

    testWidgets('cria projeto ao concluir wizard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeServiceProjetos();
      final clientService = FakeClientAccountService(
        accounts: const [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Atlas',
            ownerEmail: 'cliente@atlas.com',
            contactEmail: 'contato@atlas.com',
            contactPhone: '11999990000',
          ),
        ],
      );
      dynamic savedProject;

      await tester.pumpWidget(
        _buildHarness(
          ProjectFormDialog(
            onSave: (project) => savedProject = project,
            projectService: projectService,
            clientAccountService: clientService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Obra Atlas');
      await tester.enterText(find.byType(TextFormField).at(1), 'Cliente Atlas');

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Criar'));
      await tester.tap(find.textContaining('Criar'));
      await tester.pumpAndSettle();

      expect(projectService.lastAddedProject?.name, 'Obra Atlas');
      expect(savedProject?.clientAccountId, 'client-1');
    });
  });
}
