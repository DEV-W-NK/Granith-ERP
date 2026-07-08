import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/team_model.dart';

void main() {
  group('TeamModel', () {
    test('fromMap restaura membros, lider e projeto', () {
      final team = TeamModel.fromMap({
        'name': 'Equipe Alfa',
        'description': 'Equipe principal',
        'memberIds': ['e1', 'e2'],
        'leaderId': 'e1',
        'projectId': 'p1',
        'isActive': false,
        'createdAt': '2026-05-03T12:00:00.000Z',
        'updatedAt': '2026-05-04T12:00:00.000Z',
      }, 'team-1');

      expect(team.memberIds, ['e1', 'e2']);
      expect(team.leaderId, 'e1');
      expect(team.projectId, 'p1');
      expect(team.isActive, isFalse);
    });

    test('toMap e copyWith preservam estrutura', () {
      final team = TeamModel(
        id: 'team-1',
        name: 'Equipe Beta',
        memberIds: const ['e3'],
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );

      final updated = team.copyWith(
        description: 'Nova descricao',
        memberIds: const ['e3', 'e4'],
        isActive: false,
      );

      expect(updated.description, 'Nova descricao');
      expect(updated.memberIds, ['e3', 'e4']);
      expect(updated.isActive, isFalse);
      expect(updated.toMap()['memberIds'], ['e3', 'e4']);
    });

    test('copyWith permite limpar lider e projeto', () {
      final team = TeamModel(
        id: 'team-1',
        name: 'Equipe Beta',
        memberIds: const ['e3'],
        leaderId: 'e3',
        projectId: 'p1',
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );

      final updated = team.copyWith(leaderId: null, projectId: null);

      expect(updated.leaderId, isNull);
      expect(updated.projectId, isNull);
    });
  });
}
