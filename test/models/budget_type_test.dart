import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/budget_type.dart';

void main() {
  group('BudgetType', () {
    test('fromMap e toMap preservam dados principais', () {
      final createdAt = DateTime.utc(2026, 5, 1, 12);
      final updatedAt = DateTime.utc(2026, 5, 2, 8, 30);

      final budgetType = BudgetType.fromMap({
        'name': 'Estrutural',
        'description': 'Escopo estrutural de obra',
        'category': 'obras',
        'isActive': true,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'iconName': 'construction',
        'color': '#0055FF',
      }, 'type-1');

      final map = budgetType.toMap();

      expect(budgetType.id, 'type-1');
      expect(budgetType.name, 'Estrutural');
      expect(budgetType.createdAt.toUtc(), createdAt);
      expect(budgetType.updatedAt.toUtc(), updatedAt);
      expect(map['name'], 'Estrutural');
      expect(map['iconName'], 'construction');
      expect(map['color'], '#0055FF');
    });

    test('igualdade e hashCode consideram apenas o id', () {
      final first = BudgetType(
        id: 'type-2',
        name: 'Acabamento',
        description: 'Base',
        category: 'obras',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final second = BudgetType(
        id: 'type-2',
        name: 'Acabamento revisado',
        description: 'Outro',
        category: 'retrofit',
        isActive: false,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 2),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
