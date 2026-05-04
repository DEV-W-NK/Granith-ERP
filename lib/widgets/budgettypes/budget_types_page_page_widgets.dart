import 'package:flutter/material.dart';
import 'package:project_granith/widgets/budget_types/budget_types_page_widgets.dart';
// Mantenha o import gerado pelo seu script:

// 1. O nome da classe deve ser BudgetTypesPage (sem o View)
class BudgetTypesPage extends StatelessWidget {
  // 2. O construtor bate com o nome da classe
  const BudgetTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Retornamos a View que está na pasta widgets (sem o const)
    return BudgetsPageView();
  }
}
