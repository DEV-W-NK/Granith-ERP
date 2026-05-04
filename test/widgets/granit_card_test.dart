import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/widgets/components/GranitCard.dart';

void main() {
  group('GranitCard', () {
    testWidgets('renderiza child, titulo e responde ao tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GranitCard(
                  onTap: () => tapped = true,
                  child: const Text('Conteudo'),
                ),
                const GranitCardTitle('Resumo'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Conteudo'), findsOneWidget);
      expect(find.text('RESUMO'), findsOneWidget);

      await tester.tap(find.text('Conteudo'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
