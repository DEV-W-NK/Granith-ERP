import 'package:flutter/material.dart';
import 'package:project_granith/widgets/dailylogdetails/daily_log_details_page_page_widgets.dart';
// Importamos a View correta (o miolo da tela) que está na pasta widgets

// 1. O nome da classe deve ser exatamente o que as rotas chamam: DailyLogsPage
class DailyLogsPage extends StatelessWidget {
  
  // 2. O construtor agora possui o mesmo nome da classe
  const DailyLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Retornamos a View real definida em widgets/dailylogs/daily_logs_page_widgets.dart
    // Removemos o 'const' pois a View injeta um ViewModel (ChangeNotifier)
    return const DailyLogsPageView();
  }
}