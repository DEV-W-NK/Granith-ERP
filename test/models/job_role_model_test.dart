import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/job_role_model.dart';

void main() {
  group('JobRoleModel', () {
    test('fromMap carrega dados cadastrais do cargo sem valor financeiro', () {
      final model = JobRoleModel.fromMap({
        'title': 'Mestre de Obras',
        'sector': 'Obras',
        'requirements': ['NR-18'],
        'isActive': true,
      }, 'role-1');

      expect(model.title, 'Mestre de Obras');
      expect(model.sector, 'Obras');
      expect(model.requirements, ['NR-18']);
      expect(model.isActive, isTrue);
    });
  });
}
