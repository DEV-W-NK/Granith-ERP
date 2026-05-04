import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/supplier_model.dart';

class CNPJData {
  final String cnpj;
  final String razaoSocial;
  final String nomeFantasia;
  final String situacao;
  final String tipo;
  final String porte;
  final String naturezaJuridica;
  final String atividadePrincipal;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String municipio;
  final String uf;
  final String cep;
  final String telefone;
  final String email;
  final String dataAbertura;
  final String capitalSocial;

  CNPJData({
    required this.cnpj,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.situacao,
    required this.tipo,
    required this.porte,
    required this.naturezaJuridica,
    required this.atividadePrincipal,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.municipio,
    required this.uf,
    required this.cep,
    required this.telefone,
    required this.email,
    required this.dataAbertura,
    required this.capitalSocial,
  });

  factory CNPJData.fromJson(Map<String, dynamic> json) {
    return CNPJData(
      cnpj: json['cnpj'] ?? '',
      razaoSocial: json['nome'] ?? '',
      nomeFantasia: json['fantasia'] ?? '',
      situacao: json['situacao'] ?? '',
      tipo: json['tipo'] ?? '',
      porte: json['porte'] ?? '',
      naturezaJuridica: json['natureza_juridica'] ?? '',
      atividadePrincipal: json['atividade_principal']?[0]?['text'] ?? '',
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      municipio: json['municipio'] ?? '',
      uf: json['uf'] ?? '',
      cep: json['cep'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'] ?? '',
      dataAbertura: json['abertura'] ?? '',
      capitalSocial: json['capital_social'] ?? '',
    );
  }

  Supplier toSupplier() {
    final supplierName = nomeFantasia.isNotEmpty ? nomeFantasia : razaoSocial;

    return Supplier(
      id: '',
      name: supplierName,
      cnpj: SupplierService.limparCNPJ(cnpj),
      isActive: situacao.toLowerCase() == 'ativa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String get enderecoCompleto {
    final endereco = StringBuffer();

    if (logradouro.isNotEmpty) endereco.write(logradouro);
    if (numero.isNotEmpty) endereco.write(', $numero');
    if (complemento.isNotEmpty) endereco.write(' - $complemento');
    if (bairro.isNotEmpty) endereco.write(', $bairro');
    if (municipio.isNotEmpty) endereco.write(', $municipio');
    if (uf.isNotEmpty) endereco.write('/$uf');
    if (cep.isNotEmpty) endereco.write(' - CEP: $cep');

    return endereco.toString();
  }
}

class SupplierService {
  static const String _cnpjApiUrl = 'https://www.receitaws.com.br/v1/cnpj';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _table = 'suppliers';

  final http.Client _httpClient;

  SupplierService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<CNPJData?> consultarCNPJ(String cnpj) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);

      if (!_validarFormatoCNPJ(cnpjLimpo)) {
        throw CNPJException('CNPJ deve conter exatamente 14 digitos');
      }

      final uri = Uri.parse('$_cnpjApiUrl/$cnpjLimpo');
      final response = await _httpClient.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data.containsKey('status') && data['status'] == 'ERROR') {
          throw CNPJException(data['message'] ?? 'CNPJ nao encontrado');
        }

        return CNPJData.fromJson(data);
      }

      if (response.statusCode == 429) {
        throw CNPJException(
          'Muitas consultas. Tente novamente em alguns segundos.',
        );
      }
      if (response.statusCode == 400) {
        throw CNPJException('CNPJ invalido');
      }

      throw CNPJException('Erro no servidor (${response.statusCode})');
    } catch (e) {
      if (e is CNPJException) rethrow;
      throw CNPJException('Erro de conexao: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplierFromCNPJ(String cnpj) async {
    final cnpjData = await consultarCNPJ(cnpj);
    if (cnpjData == null) {
      throw Exception('CNPJ nao encontrado na Receita Federal');
    }

    final isAvailable = await isCnpjAvailable(cnpj);
    if (!isAvailable) {
      throw Exception('CNPJ ja cadastrado no sistema');
    }

    return createSupplier(cnpjData.toSupplier());
  }

  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await AppSupabase.client
          .from(_table)
          .select()
          .order('name');
      return (response as List).map(_supplierFromRow).toList();
    } catch (e) {
      throw Exception('Erro ao buscar fornecedores: $e');
    }
  }

  Future<Supplier?> getSupplier(String id) async {
    try {
      final row =
          await AppSupabase.client
              .from(_table)
              .select()
              .eq('id', id)
              .maybeSingle();
      if (row == null) return null;
      return _supplierFromRow(row);
    } catch (e) {
      throw Exception('Erro ao buscar fornecedor: $e');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final cleanCnpj = limparCNPJ(supplier.cnpj);
      final cnpjExists = await _cnpjExists(cleanCnpj, excludeId: supplier.id);
      if (cnpjExists) {
        throw Exception('CNPJ ja cadastrado no sistema');
      }

      final now = DateTime.now();
      final data =
          supplier
              .copyWith(cnpj: cleanCnpj, createdAt: now, updatedAt: now)
              .toJson()
            ..remove('id');

      final row =
          await AppSupabase.client
              .from(_table)
              .insert(DbValue.normalizeMap(data))
              .select('id')
              .single();

      return supplier.copyWith(
        id: row['id'] as String,
        cnpj: cleanCnpj,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Erro ao criar fornecedor: $e');
    }
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      final cleanCnpj = limparCNPJ(supplier.cnpj);
      final cnpjExists = await _cnpjExists(cleanCnpj, excludeId: supplier.id);
      if (cnpjExists) {
        throw Exception('CNPJ ja cadastrado em outro fornecedor');
      }

      final updated = supplier.copyWith(
        cnpj: cleanCnpj,
        updatedAt: DateTime.now(),
      );
      final data = updated.toJson()..remove('id');

      await AppSupabase.client
          .from(_table)
          .update(DbValue.normalizeMap(data))
          .eq('id', supplier.id);

      return updated;
    } catch (e) {
      throw Exception('Erro ao atualizar fornecedor: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await AppSupabase.client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar fornecedor: $e');
    }
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      if (query.isEmpty) return getSuppliers();

      final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
      final allSuppliers = await getSuppliers();

      return allSuppliers.where((supplier) {
        final nameMatch = supplier.name.toLowerCase().contains(
          query.toLowerCase(),
        );
        final cnpjMatch =
            supplier.cnpj.contains(cleanQuery) ||
            supplier.formattedCnpj.contains(query);

        return nameMatch || cnpjMatch;
      }).toList();
    } catch (e) {
      throw Exception('Erro na busca: $e');
    }
  }

  Future<List<Supplier>> getSuppliersByStatus(bool isActive) async {
    try {
      final response = await AppSupabase.client
          .from(_table)
          .select()
          .eq('isActive', isActive)
          .order('name');

      return (response as List).map(_supplierFromRow).toList();
    } catch (e) {
      throw Exception('Erro ao buscar fornecedores: $e');
    }
  }

  Future<Supplier> toggleSupplierStatus(String id, bool isActive) async {
    try {
      await AppSupabase.client
          .from(_table)
          .update({
            'isActive': isActive,
            'updatedAt': DbValue.toPrimitive(DateTime.now()),
          })
          .eq('id', id);

      final supplier = await getSupplier(id);
      if (supplier == null) {
        throw Exception('Fornecedor nao encontrado');
      }
      return supplier.copyWith(isActive: isActive, updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Erro ao alterar status: $e');
    }
  }

  Future<bool> isCnpjAvailable(String cnpj, {String? excludeId}) async {
    return !(await _cnpjExists(cnpj, excludeId: excludeId));
  }

  Stream<List<Supplier>> suppliersStream() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(_supplierFromRow).toList());
  }

  Stream<List<Supplier>> activeSuppliersStream() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('isActive', true)
        .order('name')
        .map((rows) => rows.map(_supplierFromRow).toList());
  }

  Future<int> getSuppliersCount() async {
    try {
      final response = await AppSupabase.client.from(_table).select('id');
      return (response as List).length;
    } catch (e) {
      throw Exception('Erro ao contar fornecedores: $e');
    }
  }

  Future<int> getActiveSuppliersCount() async {
    try {
      final response = await AppSupabase.client
          .from(_table)
          .select('id')
          .eq('isActive', true);
      return (response as List).length;
    } catch (e) {
      throw Exception('Erro ao contar fornecedores ativos: $e');
    }
  }

  Future<Supplier?> getSupplierByCnpj(String cnpj) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);
      final row =
          await AppSupabase.client
              .from(_table)
              .select()
              .eq('cnpj', cnpjLimpo)
              .limit(1)
              .maybeSingle();

      if (row == null) return null;
      return _supplierFromRow(row);
    } catch (e) {
      throw Exception('Erro ao buscar fornecedor por CNPJ: $e');
    }
  }

  Supplier _supplierFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return Supplier.fromJson(data);
  }

  Future<bool> _cnpjExists(String cnpj, {String? excludeId}) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);
      final response = await AppSupabase.client
          .from(_table)
          .select('id')
          .eq('cnpj', cnpjLimpo);

      final rows = (response as List).cast<Map<String, dynamic>>();
      if (excludeId != null && excludeId.isNotEmpty) {
        return rows.any((row) => row['id'] != excludeId);
      }

      return rows.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar CNPJ: $e');
    }
  }

  static bool validarCNPJ(String cnpj) {
    final cnpjLimpo = limparCNPJ(cnpj);

    if (cnpjLimpo.length != 14) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpjLimpo)) return false;

    try {
      final digits = cnpjLimpo.split('').map(int.parse).toList();
      const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      var sum1 = 0;
      for (var i = 0; i < 12; i++) {
        sum1 += digits[i] * weights1[i];
      }

      final remainder1 = sum1 % 11;
      final digit1 = remainder1 < 2 ? 0 : 11 - remainder1;

      if (digits[12] != digit1) return false;

      const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      var sum2 = 0;
      for (var i = 0; i < 13; i++) {
        sum2 += digits[i] * weights2[i];
      }

      final remainder2 = sum2 % 11;
      final digit2 = remainder2 < 2 ? 0 : 11 - remainder2;

      return digits[13] == digit2;
    } catch (_) {
      return false;
    }
  }

  static String formatarCNPJ(String cnpj) {
    final cnpjLimpo = limparCNPJ(cnpj);
    if (cnpjLimpo.length != 14) return cnpj;

    return '${cnpjLimpo.substring(0, 2)}.${cnpjLimpo.substring(2, 5)}.${cnpjLimpo.substring(5, 8)}/${cnpjLimpo.substring(8, 12)}-${cnpjLimpo.substring(12, 14)}';
  }

  static String limparCNPJ(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool _validarFormatoCNPJ(String cnpj) {
    return cnpj.length == 14 && RegExp(r'^\d+$').hasMatch(cnpj);
  }

  void dispose() {
    _httpClient.close();
  }
}

class CNPJException implements Exception {
  final String message;

  CNPJException(this.message);

  @override
  String toString() => message;
}
