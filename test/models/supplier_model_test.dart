import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/supplier_model.dart';

void main() {
  group('Supplier', () {
    test('formattedCnpj e validacao funcionam para cnpj numerico', () {
      final supplier = Supplier(
        id: 'supplier-1',
        name: 'Fornecedor Um',
        cnpj: '12345678000199',
        createdAt: DateTime(2026, 5, 3),
        updatedAt: DateTime(2026, 5, 3),
      );

      expect(supplier.isValidCnpj, isTrue);
      expect(supplier.formattedCnpj, '12.345.678/0001-99');
    });
  });
}
