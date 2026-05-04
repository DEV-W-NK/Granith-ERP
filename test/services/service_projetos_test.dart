import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/services/service_projetos.dart';

void main() {
  group('ServiceProjetos', () {
    test('valida assinaturas de imagem suportadas e rejeita dados invalidos', () {
      final service = ServiceProjetos();

      expect(
        service.debugIsValidImageData(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00])),
        isTrue,
      );
      expect(
        service.debugIsValidImageData(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x00]),
        ),
        isTrue,
      );
      expect(
        service.debugIsValidImageData(Uint8List.fromList([0x00, 0x11, 0x22, 0x33])),
        isFalse,
      );
    });

    test('rastreamento de operacoes expõe estatisticas e permite cancelamento', () {
      final service = ServiceProjetos();

      service.debugMarkProjectProcessing('Obra Centro', 'Cliente A', 'create');
      service.debugMarkImageUploadInProgress('p1');

      expect(
        service.isProjectCurrentlyProcessing('Obra Centro', 'Cliente A'),
        isTrue,
      );
      expect(service.hasOperationsInProgress(), isTrue);

      final stats = service.getDetailedOperationStats();
      expect(stats['projectsBeingCreated'], 1);
      expect(stats['imagesBeingUploaded'], 1);

      service.cancelProjectOperation('Obra Centro', 'Cliente A');

      expect(
        service.isProjectCurrentlyProcessing('Obra Centro', 'Cliente A'),
        isFalse,
      );
      expect((service.getDetailedOperationStats()['totalOperations'] as int) >= 1, isTrue);

      service.forceCleanAllOperations();
      expect(service.hasOperationsInProgress(), isFalse);
    });

    test('cleanup remove operacoes expiradas automaticamente', () {
      final service = ServiceProjetos();
      final old = DateTime.now().subtract(const Duration(minutes: 10));

      service.debugMarkProjectProcessing('Obra Norte', 'Cliente B', 'update');
      service.debugMarkImageUploadInProgress('p9', at: old);
      service.debugSetOperationTimestamp('obra norte_cliente b', old);

      expect(service.hasOperationsInProgress(), isFalse);
      final stats = service.getDetailedOperationStats();
      expect(stats['totalOperations'], 0);
    });

    test('waitForProjectOperationCompletion conclui quando operacao termina', () async {
      final service = ServiceProjetos();
      service.debugMarkProjectProcessing('Obra Sul', 'Cliente C', 'delete');

      Future<void>.delayed(
        const Duration(milliseconds: 20),
        () => service.cancelProjectOperation('Obra Sul', 'Cliente C'),
      );

      await service.waitForProjectOperationCompletion(
        'Obra Sul',
        'Cliente C',
        maxWait: const Duration(seconds: 1),
        checkInterval: const Duration(milliseconds: 5),
      );
    });

    test('waitForProjectOperationCompletion falha em timeout', () async {
      final service = ServiceProjetos();
      service.debugMarkProjectProcessing('Obra Leste', 'Cliente D', 'create');

      await expectLater(
        service.waitForProjectOperationCompletion(
          'Obra Leste',
          'Cliente D',
          maxWait: const Duration(milliseconds: 30),
          checkInterval: const Duration(milliseconds: 10),
        ),
        throwsException,
      );
    });
  });
}
