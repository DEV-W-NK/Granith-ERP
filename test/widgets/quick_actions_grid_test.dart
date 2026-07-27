import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

void main() {
  testWidgets('lista os modulos recebidos e delega a navegacao pelo indice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            child: QuickActionsGrid(
              modules: const [
                NavigationModule(
                  index: 1,
                  title: 'Projetos',
                  section: 'Operacional',
                  icon: Icons.business_rounded,
                  aliases: 'obras',
                ),
                NavigationModule(
                  index: 17,
                  title: 'Financeiro',
                  section: 'Financeiro',
                  icon: Icons.account_balance_rounded,
                  aliases: 'caixa',
                ),
                NavigationModule(
                  index: 29,
                  title: 'Tarefas',
                  section: 'Operacional',
                  icon: Icons.task_alt_rounded,
                  aliases: 'atividades',
                ),
              ],
              onModuleSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MODULOS DISPONIVEIS'), findsOneWidget);
    expect(find.text('3 atalhos'), findsOneWidget);
    expect(find.text('Projetos'), findsOneWidget);
    expect(find.text('Entradas e Saidas'), findsOneWidget);
    expect(find.text('Tarefas'), findsOneWidget);

    await tester.tap(find.text('Tarefas'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 29);
  });
}
