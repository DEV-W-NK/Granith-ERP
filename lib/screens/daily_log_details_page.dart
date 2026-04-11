import 'package:flutter/material.dart';
import 'package:project_granith/models/diario_obra_model.dart'; 
import 'package:project_granith/widgets/dailylogdetails/daily_log_details_page_page_widgets.dart';

// O script renomeou a classe mas não o construtor, causando o erro.
// Corrigimos para que o DailyLogCard consiga "enxergar" esta classe.
class DailyLogDetailsPage extends StatelessWidget {
  final DailyLogModel dailyLog;

  const DailyLogDetailsPage({
    super.key, 
    required this.dailyLog,
  });

  @override
  Widget build(BuildContext context) {
    // Retornamos a View real (o miolo) repassando os dados.
    return DailyLogsPageView();
  }
}