import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/widgets/financial/FinancialStatCard.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  testWidgets('FinancialStatCard renderiza valor, badge e delega tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _buildHarness(
        FinancialStatCard(
          title: 'Despesas vencidas',
          value: 15800,
          icon: Icons.warning_amber_rounded,
          color: Colors.redAccent,
          badgeCount: 3,
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despesas vencidas'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('15'), findsOneWidget);

    await tester.tap(find.byType(FinancialStatCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
