import 'package:flutter/material.dart';
import 'package:project_granith/widgets/budget_types/budget_types_page_widgets.dart';
// Certifique-se de que este import aponta para o arquivo correto do nosso Canvas

// 1. O nome da classe deve ser BudgetsPage (sem o View)
class BudgetsPage extends StatelessWidget {
  // 2. O construtor tem exatamente o mesmo nome
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Removemos o 'const' e retornamos a View que está no Canvas
    return BudgetsPageView();
  }
}
