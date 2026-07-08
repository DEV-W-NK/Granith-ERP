import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/widgets/purchases/purchases_page_page_widgets.dart';

Purchase _purchase({
  required String id,
  required String itemName,
  required String supplierName,
  required String projectName,
  required PurchaseStatus status,
  DateTime? expectedDeliveryDate,
  PurchaseFulfillmentType fulfillmentType = PurchaseFulfillmentType.delivery,
}) {
  return Purchase(
    id: id,
    itemId: 'item-$id',
    itemName: itemName,
    supplierId: 'supplier-$id',
    supplierName: supplierName,
    projectId: 'project-$id',
    projectName: projectName,
    deliveryAddress: 'Rua $id, 100',
    fulfillmentType: fulfillmentType,
    pickupAddress:
        fulfillmentType == PurchaseFulfillmentType.pickup ? 'Loja $id' : '',
    quantity: 2,
    totalValue: 1500,
    status: status,
    purchaseDate: DateTime(2026, 5, 3),
    expectedDeliveryDate: expectedDeliveryDate,
  );
}

void main() {
  testWidgets('PurchasesPageView mostra painel e filtra compras', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final purchases = [
      _purchase(
        id: '1',
        itemName: 'Cimento CP-II',
        supplierName: 'Fornecedor Atlas',
        projectName: 'Residencial Azul',
        status: PurchaseStatus.pending,
      ),
      _purchase(
        id: '2',
        itemName: 'Brita 1',
        supplierName: 'Pedreira Norte',
        projectName: 'Galpao Industrial',
        status: PurchaseStatus.awaitingApproval,
      ),
      _purchase(
        id: '3',
        itemName: 'Cabo flexivel',
        supplierName: 'Eletrica Sol',
        projectName: 'Residencial Azul',
        status: PurchaseStatus.ordered,
        fulfillmentType: PurchaseFulfillmentType.pickup,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PurchasesPageView(purchasesStream: Stream.value(purchases)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Nova compra'), findsOneWidget);
    expect(find.text('3 de 3 compras'), findsOneWidget);
    expect(find.text('Cimento CP-II'), findsOneWidget);
    expect(find.text('Brita 1'), findsOneWidget);
    expect(find.text('Cabo flexivel'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Brita');
    await tester.pump();

    expect(find.text('1 de 3 compras'), findsOneWidget);
    expect(find.text('Brita 1'), findsOneWidget);
    expect(find.text('Cimento CP-II'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.tap(find.text('Consolidadas'));
    await tester.pump();

    expect(find.text('1 de 3 compras'), findsOneWidget);
    expect(find.text('Cabo flexivel'), findsOneWidget);
    expect(find.text('Brita 1'), findsNothing);
  });
}
