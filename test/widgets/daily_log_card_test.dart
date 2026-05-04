import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_card.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_daily_log_controller.dart';

void main() {
  testWidgets('DailyLogCard renderiza resumo e abre tela de detalhes', (
    tester,
  ) async {
    final controller = FakeDailyLogController();
    final log = DailyLogModel(
      id: 'log-1',
      projectId: 'p1',
      projectName: 'Obra Centro',
      date: DateTime(2026, 5, 3),
      weatherMorning: WeatherCondition.nublado,
      activitiesDescription: 'Concretagem da laje',
      createdByUserId: 'u1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DailyLogController>.value(
        value: controller,
        child: MaterialApp(
          home: Scaffold(body: DailyLogCard(log: log)),
        ),
      ),
    );

    expect(find.text('Obra Centro'), findsOneWidget);
    expect(find.text('Concretagem da laje'), findsOneWidget);
    expect(find.text('nublado'), findsOneWidget);

    await tester.tap(find.byType(DailyLogCard));
    await tester.pumpAndSettle();

    expect(find.text('Diário de Obras'), findsOneWidget);
  });
}
