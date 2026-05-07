import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/employee_model.dart';

void main() {
  group('EmployeeModel', () {
    test('getters de status e iniciais refletem estado do funcionario', () {
      final employee = EmployeeModel(
        id: 'emp-1',
        name: 'Joao Silva',
        email: 'joao@empresa.com',
        phone: '11999990000',
        jobTitle: 'Pedreiro',
        sector: 'Obras',
        role: EmployeeRole.funcionario,
        status: EmployeeStatus.ferias,
        admissionDate: DateTime(2025, 1, 10),
        baseSalary: 3200,
        educationLevel: 'Medio',
        createdAt: DateTime(2025, 1, 10),
        updatedAt: DateTime(2026, 5, 3),
      );

      expect(employee.initials, 'JS');
      expect(employee.isActive, isFalse);
      expect(employee.isOnLeave, isTrue);
      expect(employee.isDismissed, isFalse);
    });

    test('fromMap aceita salary legado como fallback de baseSalary', () {
      final employee = EmployeeModel.fromMap({
        'name': 'Maria Souza',
        'email': 'maria@empresa.com',
        'phone': '11988887777',
        'jobTitle': 'Engenheira',
        'sector': 'Projetos',
        'role': 'coordenador',
        'status': 'ativo',
        'admissionDate': '2024-03-01T00:00:00.000',
        'salary': 8500,
        'educationLevel': 'Superior',
        'courses': 'PMP',
        'createdAt': '2024-03-01T00:00:00.000',
        'updatedAt': '2026-05-03T00:00:00.000',
      }, 'emp-2');

      expect(employee.baseSalary, 8500);
      expect(employee.role, EmployeeRole.coordenador);
      expect(employee.status, EmployeeStatus.ativo);
    });

    test('hierarquia reconhece gerente como maior nivel operacional', () {
      final employee = EmployeeModel.fromMap({
        'name': 'Helena Duarte',
        'email': 'helena@empresa.com',
        'phone': '11977776666',
        'jobTitle': 'Gerente de Obras',
        'sector': 'Operacional',
        'role': 'gerente',
        'status': 'ativo',
        'baseSalary': 12500,
        'educationLevel': 'Superior',
      }, 'emp-3');

      expect(employee.role, EmployeeRole.gerente);
      expect(employee.role.level, greaterThan(EmployeeRole.coordenador.level));
      expect(employee.role.isManager, isTrue);
    });

    test('rotulos da hierarquia seguem os niveis do Mobile', () {
      expect(EmployeeRole.funcionario.label, 'Colaborador');
      expect(EmployeeRole.supervisor.label, 'Supervisao');
      expect(EmployeeRole.coordenador.label, 'Coordenacao');
      expect(EmployeeRole.gerente.label, 'Gerencia');
    });

    test('fromMap aceita baseSalary numerico em string', () {
      final employee = EmployeeModel.fromMap({
        'name': 'Pedro Lima',
        'email': 'pedro@empresa.com',
        'phone': '11977776666',
        'jobTitle': 'Analista',
        'sector': 'RH',
        'role': 'funcionario',
        'status': 'ativo',
        'baseSalary': '4321.50',
        'educationLevel': 'Superior',
      }, 'emp-4');

      expect(employee.baseSalary, 4321.5);
    });
  });
}
