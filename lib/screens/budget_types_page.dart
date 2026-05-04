import 'package:flutter/material.dart';
// 1. CORREÇÃO: O import agora aponta para a pasta e arquivo corretos
import 'package:project_granith/widgets/budget_types/budget_types_page_widgets.dart';

class BudgetTypesPage extends StatelessWidget {
  const BudgetTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Agora ele vai encontrar essa classe com sucesso!
    return BudgetsPageView();
  }
}
