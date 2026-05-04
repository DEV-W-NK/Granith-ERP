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
    });

    test('toMap e copyWith atualizam estado e descricao', () {
      final model = BenefitModel(
        id: 'b1',
        name: 'VR',
        type: BenefitType.vr,
        description: 'Inicial',
        createdAt: DateTime(2026, 5, 3),
      );

      final updated = model.copyWith(description: 'Atualizado', isActive: false);

      expect(updated.description, 'Atualizado');
      expect(updated.isActive, isFalse);
      expect(updated.toMap()['type'], 'vr');
    });
  });
}
