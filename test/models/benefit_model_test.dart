import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/BenefitModel.dart';

void main() {
  group('BenefitModel', () {
    test('typeLabel traduz tipos conhecidos e usa fallback no fromMap', () {
      final vt = BenefitModel(
        id: 'b1',
        name: 'VT',
        type: BenefitType.vt,
        createdAt: DateTime(2026, 5, 3),
      );

      expect(vt.typeLabel, 'Vale Transporte');

      final other = BenefitModel.fromMap({
        'name': 'Auxilio',
        'type': 'nao_mapeado',
        'createdAt': '2026-05-03T00:00:00.000Z',
      }, 'b2');

      expect(other.type, BenefitType.other);
      expect(other.typeLabel, 'Outro');
      expect(other.valueMode, BenefitValueMode.fixedMonthly);
      expect(other.defaultValue, 0);
      expect(other.reimbursementLimit, 0);
    });

    test('toMap e copyWith atualizam estado, descricao e valores', () {
      final model = BenefitModel(
        id: 'b1',
        name: 'VR',
        type: BenefitType.vr,
        categoryId: 'cat-1',
        categoryName: 'Vales',
        valueMode: BenefitValueMode.fixedMonthly,
        defaultValue: 450,
        description: 'Inicial',
        createdAt: DateTime(2026, 5, 3),
      );

      final updated = model.copyWith(
        categoryId: 'cat-2',
        categoryName: 'Alimentacao',
        valueMode: BenefitValueMode.reimbursement,
        defaultValue: 0,
        reimbursementLimit: 320,
        description: 'Atualizado',
        isActive: false,
      );

      expect(updated.categoryId, 'cat-2');
      expect(updated.categoryName, 'Alimentacao');
      expect(updated.description, 'Atualizado');
      expect(updated.isActive, isFalse);
      expect(updated.valueMode, BenefitValueMode.reimbursement);
      expect(updated.suggestedAssignmentValue, 320);
      expect(updated.toMap()['type'], 'vr');
      expect(updated.toMap()['categoryId'], 'cat-2');
      expect(updated.toMap()['valueMode'], 'reimbursement');
      expect(updated.toMap()['defaultValue'], 0);
      expect(updated.toMap()['reimbursementLimit'], 320);
    });

    test('copyWith permite limpar categoria', () {
      final model = BenefitModel(
        id: 'b1',
        name: 'Plano',
        type: BenefitType.health,
        categoryId: 'cat-1',
        categoryName: 'Saude',
        createdAt: DateTime(2026, 5, 3),
      );

      final updated = model.copyWith(clearCategory: true);

      expect(updated.categoryId, isNull);
      expect(updated.categoryName, isEmpty);
    });

    test('fromMap restaura reembolso e legado isReimbursable', () {
      final mapped = BenefitModel.fromMap({
        'name': 'Reembolso combustivel',
        'type': 'other',
        'valueMode': 'reimbursement',
        'defaultValue': '0',
        'reimbursementLimit': '750.50',
        'createdAt': '2026-05-03T00:00:00.000Z',
      }, 'b3');

      expect(mapped.valueModeLabel, 'Reembolso');
      expect(mapped.reimbursementLimit, 750.50);
      expect(mapped.suggestedAssignmentValue, 750.50);

      final legacy = BenefitModel.fromMap({
        'name': 'Reembolso legado',
        'type': 'other',
        'isReimbursable': true,
      }, 'b4');

      expect(legacy.valueMode, BenefitValueMode.reimbursement);
    });
  });
}
