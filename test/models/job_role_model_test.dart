import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/job_role_model.dart';

void main() {
  group('JobRoleModel', () {
    test('fromMap aceita hourlyRate numerico em string', () {
      final model = JobRoleModel.fromMap({
        'title': 'Mestre de Obras',
        'sector': 'Obras',
        'hourlyRate': '42.75',
        'requirements': ['NR-18'],
        'isActive': true,
      }, 'role-1');

      expect(model.hourlyRate, 42.75);
      expect(model.requirements, ['NR-18']);
      expect(model.isActive, isTrue);
    });
  });
}
