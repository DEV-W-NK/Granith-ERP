import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/widgets/supplier/supplier_card.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 900, height: 260, child: child)),
  );
}

void main() {
  group('SupplierCard', () {
    testWidgets('renderiza fornecedor ativo em lista e delega acoes', (
      tester,
    ) async {
      var viewed = false;
      var edited = false;
      var toggled = false;
      var deleted = false;

      final supplier = Supplier(
        id: 'sup-1',
        name: 'Fornecedor Atlas',
        cnpj: '12345678000199',
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 2),
      );

      await tester.pumpWidget(
        _buildHarness(
          SupplierCard(
            supplier: supplier,
            isListView: true,
            onTap: () => viewed = true,
            onEdit: () => edited = true,
            onToggleStatus: () => toggled = true,
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fornecedor Atlas'), findsOneWidget);
      expect(find.text('12.345.678/0001-99'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.textContaining('Criado em 1 mai 2026'), findsOneWidget);

      await tester.tap(find.text('Fornecedor Atlas'));
      await tester.pumpAndSettle();
      expect(viewed, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desativar'));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('renderiza fornecedor inativo em grid', (tester) async {
      final supplier = Supplier(
        id: 'sup-2',
        name: 'Fornecedor Sul',
        cnpj: '00987654000155',
        isActive: false,
        createdAt: DateTime(2025, 12, 10),
        updatedAt: DateTime(2026, 1, 2),
      );

      await tester.pumpWidget(
        _buildHarness(SupplierCard(supplier: supplier, isListView: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fornecedor Sul'), findsOneWidget);
      expect(find.text('Inativo'), findsOneWidget);
      expect(find.text('00.987.654/0001-55'), findsOneWidget);
    });
  });
}
