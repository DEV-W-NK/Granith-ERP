import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/diario_obra_model.dart';

void main() {
  group('DailyLogModel', () {
    test('toMap e fromMap preservam clima, mao de obra e fotos', () {
      final date = DateTime(2026, 5, 3, 8);
      final requestedAt = DateTime(2026, 5, 3, 18);
      final log = DailyLogModel(
        id: 'log-1',
        projectId: 'project-1',
        projectName: 'Obra Alfa',
        date: date,
        weatherMorning: WeatherCondition.nublado,
        weatherAfternoon: WeatherCondition.chuvoso,
        manpower: const {'pedreiro': 4, 'servente': 2},
        activitiesDescription: 'Concretagem da laje',
        impediments: 'Chuva leve no periodo da tarde',
        photoUrls: const ['https://cdn/img1.jpg'],
        createdByUserId: 'user-1',
        status: LogStatus.pendingSignature,
        coordinatorId: 'coord-1',
        coordinatorName: 'Ana Coordenadora',
        signatureRequestedAt: requestedAt,
      );

      final map = log.toMap();
      final restored = DailyLogModel.fromMap({
        ...map,
        'date': date.toIso8601String(),
      }, 'log-1');

      expect(restored.projectName, 'Obra Alfa');
      expect(restored.weatherMorning, WeatherCondition.nublado);
      expect(restored.weatherAfternoon, WeatherCondition.chuvoso);
      expect(restored.manpower['pedreiro'], 4);
      expect(restored.photoUrls, ['https://cdn/img1.jpg']);
      expect(restored.status, LogStatus.pendingSignature);
      expect(restored.coordinatorId, 'coord-1');
      expect(restored.coordinatorName, 'Ana Coordenadora');
      expect(restored.signatureRequestedAt, requestedAt);
      expect(restored.isPendingSignature, isTrue);
    });

    test('copyWith registra assinatura do coordenador', () {
      final log = DailyLogModel(
        id: 'log-1',
        projectId: 'project-1',
        projectName: 'Obra Alfa',
        date: DateTime(2026, 5, 3, 8),
        activitiesDescription: 'Concretagem da laje',
        createdByUserId: 'user-1',
        status: LogStatus.pendingSignature,
        coordinatorId: 'coord-1',
        coordinatorName: 'Ana Coordenadora',
      );
      final signedAt = DateTime(2026, 5, 3, 19);

      final signed = log.copyWith(
        status: LogStatus.signed,
        signedAt: signedAt,
        signedByCoordinatorId: 'coord-1',
        signedByCoordinatorName: 'Ana Coordenadora',
      );

      expect(signed.isSigned, isTrue);
      expect(signed.isPendingSignature, isFalse);
      expect(signed.signedAt, signedAt);
      expect(signed.signedByCoordinatorName, 'Ana Coordenadora');
    });
  });
}
