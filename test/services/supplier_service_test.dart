import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/supplier_service.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

class _StubSupplierService extends SupplierService {
  _StubSupplierService({
    required this.cnpjData,
    this.available = true,
    List<Supplier>? suppliers,
  }) : _suppliers = List<Supplier>.from(suppliers ?? const <Supplier>[]);

  final CNPJData? cnpjData;
  final bool available;
  final List<Supplier> _suppliers;
  Supplier? lastCreatedSupplier;

  @override
  Future<CNPJData?> consultarCNPJ(String cnpj) async => cnpjData;

  @override
  Future<bool> isCnpjAvailable(String cnpj, {String? excludeId}) async => available;

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    lastCreatedSupplier = supplier;
    final created = supplier.copyWith(id: 'supplier-created');
    _suppliers.add(created);
    return created;
  }

  @override
  Future<List<Supplier>> getSuppliers() async => List<Supplier>.from(_suppliers);
}

void main() {
  group('SupplierService', () {
    test(
      'consultarCNPJ retorna dados parseados quando API responde com sucesso',
      () async {
        final service = SupplierService(
          httpClient: _FakeHttpClient((request) async {
            expect(
              request.url.toString(),
              'https://www.receitaws.com.br/v1/cnpj/12345678000195',
            );
            return http.Response(
              jsonEncode({
                'cnpj': '12.345.678/0001-95',
                'nome': 'Fornecedor Alfa Ltda',
                'fantasia': 'Alfa',
                'situacao': 'ATIVA',
                'atividade_principal': [
                  {'text': 'Comercio varejista'},
                ],
                'logradouro': 'Rua Central',
                'numero': '100',
                'bairro': 'Centro',
                'municipio': 'Sao Paulo',
                'uf': 'SP',
                'cep': '01001000',
              }),
              200,
            );
          }),
        );

        final result = await service.consultarCNPJ('12.345.678/0001-95');

        expect(result, isNotNull);
        expect(result!.razaoSocial, 'Fornecedor Alfa Ltda');
        expect(result.nomeFantasia, 'Alfa');
        expect(result.atividadePrincipal, 'Comercio varejista');
        expect(result.enderecoCompleto, contains('Rua Central, 100'));
      },
    );

    test(
      'consultarCNPJ falha para formato invalido e para limite de consultas',
      () async {
        final service = SupplierService(
          httpClient: _FakeHttpClient((_) async => http.Response('', 429)),
        );

        expect(
          () => service.consultarCNPJ('123'),
          throwsA(
            isA<CNPJException>().having(
              (error) => error.message,
              'message',
              contains('14'),
            ),
          ),
        );

        expect(
          () => service.consultarCNPJ('12345678000195'),
          throwsA(
            isA<CNPJException>().having(
              (error) => error.message,
              'message',
              contains('Muitas consultas'),
            ),
          ),
        );
      },
    );

    test('utilitarios de CNPJ formatam, limpam e validam corretamente', () {
      expect(
        SupplierService.limparCNPJ('12.345.678/0001-95'),
        '12345678000195',
      );
      expect(
        SupplierService.formatarCNPJ('12345678000195'),
        '12.345.678/0001-95',
      );
      expect(SupplierService.validarCNPJ('11222333000181'), isTrue);
      expect(SupplierService.validarCNPJ('11111111111111'), isFalse);
    });

    test('createSupplierFromCNPJ converte dados consultados em fornecedor', () async {
      final service = _StubSupplierService(
        cnpjData: CNPJData(
          cnpj: '12.345.678/0001-95',
          razaoSocial: 'Fornecedor Alfa Ltda',
          nomeFantasia: 'Alfa',
          situacao: 'ATIVA',
          tipo: 'MATRIZ',
          porte: 'ME',
          naturezaJuridica: 'LTDA',
          atividadePrincipal: 'Comercio',
          logradouro: 'Rua Central',
          numero: '100',
          complemento: '',
          bairro: 'Centro',
          municipio: 'Sao Paulo',
          uf: 'SP',
          cep: '01001000',
          telefone: '',
          email: '',
          dataAbertura: '',
          capitalSocial: '',
        ),
      );

      final created = await service.createSupplierFromCNPJ('12345678000195');

      expect(created.id, 'supplier-created');
      expect(created.name, 'Alfa');
      expect(service.lastCreatedSupplier?.cnpj, '12345678000195');
      expect(service.lastCreatedSupplier?.isActive, isTrue);
    });

    test('createSupplierFromCNPJ bloqueia duplicidade quando CNPJ nao esta disponivel', () async {
      final service = _StubSupplierService(
        cnpjData: CNPJData(
          cnpj: '12.345.678/0001-95',
          razaoSocial: 'Fornecedor Alfa Ltda',
          nomeFantasia: 'Alfa',
          situacao: 'ATIVA',
          tipo: 'MATRIZ',
          porte: 'ME',
          naturezaJuridica: 'LTDA',
          atividadePrincipal: 'Comercio',
          logradouro: '',
          numero: '',
          complemento: '',
          bairro: '',
          municipio: '',
          uf: '',
          cep: '',
          telefone: '',
          email: '',
          dataAbertura: '',
          capitalSocial: '',
        ),
        available: false,
      );

      await expectLater(
        () => service.createSupplierFromCNPJ('12345678000195'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('ja cadastrado'),
          ),
        ),
      );
    });

    test('searchSuppliers filtra por nome e por CNPJ formatado', () async {
      final service = _StubSupplierService(
        cnpjData: null,
        suppliers: [
          Supplier(
            id: 'supplier-1',
            name: 'Fornecedor Alfa',
            cnpj: '12345678000195',
            createdAt: DateTime(2026, 5, 3),
            updatedAt: DateTime(2026, 5, 3),
          ),
          Supplier(
            id: 'supplier-2',
            name: 'Fornecedor Beta',
            cnpj: '98765432000166',
            createdAt: DateTime(2026, 5, 3),
            updatedAt: DateTime(2026, 5, 3),
          ),
        ],
      );

      final byName = await service.searchSuppliers('beta');
      final byCnpj = await service.searchSuppliers('12.345.678/0001-95');

      expect(byName.single.id, 'supplier-2');
      expect(byCnpj.single.id, 'supplier-1');
    });
  });
}
