import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/widgets/supplier/suppliers_header.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_supplier_service.dart';

void main() {
  Supplier supplier({
    required String id,
    required String name,
    required bool isActive,
  }) {
    return Supplier(
      id: id,
      name: name,
      cnpj: '19131243000197',
      isActive: isActive,
      createdAt: DateTime(2026, 5, 3),
      updatedAt: DateTime(2026, 5, 3),
    );
  }

  testWidgets('SuppliersHeader mostra contagem, alterna modo e abre exportacao', (
    tester,
  ) async {
    final controller = SupplierController(
      FakeSupplierService(
        initialSuppliers: [
          supplier(id: '1', name: 'Alpha', isActive: true),
          supplier(id: '2', name: 'Beta', isActive: false),
        ],
      ),
    );
    await controller.loadSuppliers();

    await tester.pumpWidget(
      ChangeNotifierProvider<SupplierController>.value(
        value: controller,
        child: const MaterialApp(
          home: Scaffold(body: SuppliersHeader(isDesktop: true)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fornecedores'), findsOneWidget);
    expect(find.textContaining('2 fornecedores'), findsOneWidget);
    expect(find.text('1 ativos'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.isGridView, isFalse);

    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Exportar Fornecedores'), findsOneWidget);
    expect(find.text('Exportar como CSV'), findsOneWidget);
  });
}
