import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/widgets/suppliers/suppliers_page_page_widgets.dart';

import '../helpers/fake_supplier_service.dart';

void main() {
  Supplier supplier({
    required String id,
    required String name,
  }) {
    return Supplier(
      id: id,
      name: name,
      cnpj: '19131243000197',
      createdAt: DateTime(2026, 5, 3),
      updatedAt: DateTime(2026, 5, 3),
    );
  }

  testWidgets('SuppliersPageView renderiza lista ou vazio com controller injetado', (
    tester,
  ) async {
    final populated = SupplierController(
      FakeSupplierService(
        initialSuppliers: [supplier(id: '1', name: 'Fornecedor X')],
      ),
    );
    await populated.loadSuppliers();

    await tester.pumpWidget(
      MaterialApp(home: SuppliersPageView(controller: populated)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Fornecedor X'), findsOneWidget);

    final empty = SupplierController(FakeSupplierService());
    await empty.loadSuppliers();

    await tester.pumpWidget(
      MaterialApp(home: SuppliersPageView(controller: empty)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Nenhum fornecedor encontrado.'), findsOneWidget);
  });
}
