import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/hr/hrpage_page_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_team_service.dart';

EmployeeModel _employee({
  required String id,
  required String name,
  required EmployeeStatus status,
  EmployeeRole role = EmployeeRole.funcionario,
}) {
  return EmployeeModel(
    id: id,
    name: name,
    email: '$id@granith.com',
    phone: '11999999999',
    jobTitle: 'Encarregado de Obras',
    sector: 'Operacional',
    role: role,
    status: status,
    admissionDate: DateTime(2026, 1, 1),
    baseSalary: 4200,
    educationLevel: 'Tecnico completo',
    courses: 'NR-18, Seguranca do Trabalho',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('HrPageView', () {
    for (final size in const [
      Size(390, 900),
      Size(768, 1024),
      Size(1280, 900),
    ]) {
      testWidgets('renderiza sem overflow em ${size.width}px', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final service = FakeTeamService(
          employees: [
            _employee(
              id: 'ana',
              name: 'Ana Carolina Mendes',
              status: EmployeeStatus.ativo,
              role: EmployeeRole.gerente,
            ),
            _employee(
              id: 'bruno',
              name: 'Bruno Almeida',
              status: EmployeeStatus.ferias,
              role: EmployeeRole.supervisor,
            ),
            _employee(
              id: 'carla',
              name: 'Carla Souza',
              status: EmployeeStatus.afastado,
            ),
          ],
        );
        final controller = TeamController(service: service);

        await tester.pumpWidget(
          ChangeNotifierProvider<TeamController>.value(
            value: controller,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const HrPageView(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Recursos Humanos'), findsOneWidget);
        expect(find.text('Setores'), findsOneWidget);
        expect(find.text('Ana Carolina Mendes'), findsOneWidget);
        expect(find.text('Salario restrito'), findsWidgets);
        expect(tester.takeException(), isNull);

        controller.dispose();
        await service.disposeControllers();
      });
    }
  });
}
