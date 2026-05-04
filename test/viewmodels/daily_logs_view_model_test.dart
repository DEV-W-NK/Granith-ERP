import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/DailyLogsViewModel.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import '../helpers/fake_daily_log_controller.dart';

void main() {
  group('DailyLogsViewModel', () {
    testWidgets('dispara carga inicial apos primeiro frame', (tester) async {
      final controller = FakeDailyLogController();

      DailyLogsViewModel(controller);
      expect(controller.loadLogsCalled, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(controller.loadLogsCalled, isTrue);
    });

    testWidgets('espelha logs e estado de carregamento do controller', (
      tester,
    ) async {
      final controller = FakeDailyLogController();
      final viewModel = DailyLogsViewModel(controller);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      controller.emit(
        isLoading: true,
        logs: [
          DailyLogModel(
            id: 'log-1',
            projectId: 'project-1',
            projectName: 'Obra Alfa',
            date: DateTime(2026, 5, 3),
            activitiesDescription: 'Concretagem',
            createdByUserId: 'user-1',
          ),
        ],
      );

      expect(viewModel.isLoading, isTrue);
      expect(viewModel.logs, hasLength(1));
      expect(viewModel.getAiInsight(), contains('Analise de IA'));
    });
  });
}
