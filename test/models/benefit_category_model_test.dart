import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/BenefitCategoryModel.dart';

void main() {
  group('BenefitCategoryModel', () {
    test('fromMap restaura dados e aplica defaults', () {
      final category = BenefitCategoryModel.fromMap({
        'name': 'Saude',
        'description': 'Planos medicos e odontologicos',
        'createdAt': '2026-05-03T00:00:00.000Z',
        'updatedAt': '2026-05-04T00:00:00.000Z',
      }, 'cat-1');

      expect(category.id, 'cat-1');
      expect(category.name, 'Saude');
      expect(category.isActive, isTrue);
      expect(category.description, 'Planos medicos e odontologicos');
    });

    test('toMap e copyWith atualizam estado', () {
      final category = BenefitCategoryModel(
        id: 'cat-1',
        name: 'Vales',
        description: 'Beneficios recorrentes',
        createdAt: DateTime(2026, 5, 3),
        updatedAt: DateTime(2026, 5, 3),
      );

      final updated = category.copyWith(
        name: 'Vales e auxilios',
        isActive: false,
        updatedAt: DateTime(2026, 5, 4),
      );

      expect(updated.name, 'Vales e auxilios');
      expect(updated.isActive, isFalse);
      expect(updated.toMap()['isActive'], isFalse);
    });
  });
}
