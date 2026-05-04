import 'package:flutter/material.dart';
import 'package:project_granith/widgets/dailylogdetails/daily_log_details_page_page_widgets.dart';
// Importamos a View correta (o miolo da tela) que está na pasta de apresentação

// 1. O nome da classe deve ser exatamente o que as rotas/Navigator chamam: DailyLogsPage
class DailyLogsPage extends StatelessWidget {
  // 2. O construtor deve ter o mesmo nome da classe para ser válido no Dart
  const DailyLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Retornamos a View real (DailyLogsPageView) definida no arquivo de widgets.
    // Removido o 'const' pois a View injeta um ViewModel que impede a construção constante.
    return const DailyLogsPageView();
  }
}
