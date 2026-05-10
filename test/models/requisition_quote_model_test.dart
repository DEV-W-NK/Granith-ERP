import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/requisition_quote_model.dart';

void main() {
  group('RequisitionSupplierQuote', () {
    test('fromMap calcula total negociado e status selecionado', () {
      final now = DateTime(2026, 5, 9, 11);
      final quote = RequisitionSupplierQuote.fromMap({
        'id': 'quote-1',
        'requisitionId': 'req-1',
        'supplierId': 'supplier-1',
        'supplierName': 'Fornecedor A',
        'totalValue': 1500,
        'freightValue': 125.5,
        'deliveryDays': 3,
        'paymentTerms': '28 dias',
        'quoteItems': [
          {'itemName': 'Cimento', 'quantity': 10, 'unit': 'sc'},
        ],
        'status': 'selected',
        'isSelected': true,
        'quotedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(quote.status, RequisitionQuoteStatus.selected);
      expect(quote.isSelected, isTrue);
      expect(quote.negotiatedTotal, 1625.5);
      expect(quote.quoteItems.single['itemName'], 'Cimento');
    });
  });
}
