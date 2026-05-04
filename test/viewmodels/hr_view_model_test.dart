import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/HrViewModel.dart';
import 'package:project_granith/models/employee_model.dart';
import '../helpers/fake_hr_service.dart';

void main() {
  group('HrViewModel', () {
    EmployeeModel employee({
      required String id,
      required String name,
      required EmployeeStatus status,
    }) {
      return EmployeeModel(
        id: id,
        name: name,
        email: '$id@empresa.com',
        phone: '11999990000',
        jobTitle: 'Cargo',
        sector: 'Obras',
        role: EmployeeRole.funcionario,
        status: status,
        admissionDate: DateTime(2025, 1, 1),
        baseSalary: 3000,
        educationLevel: 'Medio',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2026, 5, 3),
      );
    }

    test('updateSearch altera consulta atual', () {
      final viewModel = HrViewModel(FakeHrService());

      viewModel.updateSearch('maria');

      expect(viewModel.searchQuery, 'maria');
    });

    test('getEmployeeStats consolida ativos, ferias e desligados', () {
      final viewModel = HrViewModel(FakeHrService());
      final stats = viewModel.getEmployeeStats([
        employee(id: '1', name: 'Joao', status: EmployeeStatus.ativo),
        employee(id: '2', name: 'Maria', status: EmployeeStatus.ferias),
        employee(id: '3', name: 'Carlos', status: EmployeeStatus.desligado),
        employee(id: '4', name: 'Ana', status: EmployeeStatus.ativo),
      ]);

      expect(stats['ativos'], 2);
      expect(stats['ferias'], 1);
      expect(stats['desligados'], 1);
    });
  });
}
