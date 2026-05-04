import 'package:flutter/material.dart';
// Verifique se o nome do arquivo abaixo está correto no seu VS Code.
// Se o erro persistir, abra o arquivo 'financialpage_page_widgets.dart'
// e confirme se o nome da classe lá dentro é exatamente 'FinancialPageView'.
import 'package:project_granith/widgets/financial/financialpage_page_widgets.dart';

// Esta é a "casca" que o Navigator do seu App chama.
class FinancialPage extends StatelessWidget {
  // O construtor deve ser idêntico ao nome da classe.
  const FinancialPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Aqui chamamos o "miolo" da tela que está na pasta widgets.
    // Se o erro 'undefined_method' continuar, é porque o nome da classe
    // no arquivo importado é diferente de 'FinancialPageView'.
    return FinancialPageView();
  }
}
