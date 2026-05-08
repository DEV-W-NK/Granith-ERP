import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/widgets/employee/employee_card.dart';

EmployeeModel _employee() {
  return EmployeeModel(
    id: 'employee-1',
    name: 'Ana Mendes',
    email: 'ana@granith.com',
    phone: '11999999999',
    jobTitle: 'Coordenadora',
    sector: 'RH',
    role: EmployeeRole.coordenador,
    status: EmployeeStatus.ativo,
    admissionDate: DateTime(2026, 1, 1),
    baseSalary: 4200,
    educationLevel: 'Superior completo',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('EmployeeCard mascara salario sem permissao', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: _employee(),
            canViewSalary: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Salario restrito'), findsOneWidget);
    expect(find.textContaining('Salario:'), findsNothing);
  });

  testWidgets('EmployeeCard mostra salario com permissao', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: _employee(),
            canViewSalary: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Salario:'), findsOneWidget);
    expect(find.text('Salario restrito'), findsNothing);
  });
}
