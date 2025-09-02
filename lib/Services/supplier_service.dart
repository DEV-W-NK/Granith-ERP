import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/supplier_model.dart';

// Classe para dados do CNPJ da ReceitaWS
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

  // Converte CNPJData para Supplier (para pré-preenchimento)
  Supplier toSupplier() {
    // Prioriza nome fantasia, se não tiver usa razão social
    final supplierName = nomeFantasia.isNotEmpty ? nomeFantasia : razaoSocial;

    return Supplier(
      id: '', // Será gerado pelo Firestore
      name: supplierName,
      cnpj: SupplierService.limparCNPJ(cnpj), // Salva apenas números
      isActive: situacao.toLowerCase() == 'ativa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Getter para endereço completo formatado
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
  static const String _collection = 'suppliers';

  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  SupplierService({FirebaseFirestore? firestore, http.Client? httpClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _httpClient = httpClient ?? http.Client();

  // ==================== CNPJ CONSULTATION METHODS ====================

  /// Consulta dados de uma empresa pelo CNPJ usando ReceitaWS
  Future<CNPJData?> consultarCNPJ(String cnpj) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);

      if (!_validarFormatoCNPJ(cnpjLimpo)) {
        throw CNPJException('CNPJ deve conter exatamente 14 dígitos');
      }

      final uri = Uri.parse('$_cnpjApiUrl/$cnpjLimpo');

      final response = await _httpClient.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('status') && data['status'] == 'ERROR') {
          throw CNPJException(data['message'] ?? 'CNPJ não encontrado');
        }

        return CNPJData.fromJson(data);
      } else if (response.statusCode == 429) {
        throw CNPJException(
          'Muitas consultas. Tente novamente em alguns segundos.',
        );
      } else if (response.statusCode == 400) {
        throw CNPJException('CNPJ inválido');
      } else {
        throw CNPJException('Erro no servidor (${response.statusCode})');
      }
    } catch (e) {
      if (e is CNPJException) {
        rethrow;
      } else {
        throw CNPJException('Erro de conexão: ${e.toString()}');
      }
    }
  }

  /// Cria supplier automaticamente com dados do CNPJ
  Future<Supplier> createSupplierFromCNPJ(String cnpj) async {
    try {
      // 1. Consulta dados da ReceitaWS
      final cnpjData = await consultarCNPJ(cnpj);

      if (cnpjData == null) {
        throw Exception('CNPJ não encontrado na Receita Federal');
      }

      // 2. Verifica se CNPJ já existe no Firestore
      final isAvailable = await isCnpjAvailable(cnpj);
      if (!isAvailable) {
        throw Exception('CNPJ já cadastrado no sistema');
      }

      // 3. Converte para Supplier e salva no Firestore
      final supplier = cnpjData.toSupplier();
      return await createSupplier(supplier);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== FIRESTORE CRUD METHODS ====================

  /// Busca todos os fornecedores
  Future<List<Supplier>> getSuppliers() async {
    try {
      final querySnapshot =
          await _firestore.collection(_collection).orderBy('name').get();

      return querySnapshot.docs
          .map((doc) => Supplier.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar fornecedores: ${e.message}');
    }
  }

  /// Busca fornecedor por ID
  Future<Supplier?> getSupplier(String id) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(id).get();

      if (docSnapshot.exists) {
        return Supplier.fromJson({
          ...docSnapshot.data()!,
          'id': docSnapshot.id,
        });
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar fornecedor: ${e.message}');
    }
  }

  /// Cria novo fornecedor
  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      // Verifica se CNPJ já existe
      final cnpjExists = await _cnpjExists(
        supplier.cnpj,
        excludeId: supplier.id,
      );
      if (cnpjExists) {
        throw Exception('CNPJ já cadastrado no sistema');
      }

      final supplierData = supplier.toJson();
      supplierData.remove('id'); // Remove ID para auto-gerar

      // Adiciona timestamp do servidor
      supplierData['createdAt'] = FieldValue.serverTimestamp();
      supplierData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_collection).add(supplierData);

      return supplier.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw Exception('Erro ao criar fornecedor: ${e.message}');
    }
  }

  /// Atualiza fornecedor existente
  Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      // Verifica se CNPJ já existe em outro fornecedor
      final cnpjExists = await _cnpjExists(
        supplier.cnpj,
        excludeId: supplier.id,
      );
      if (cnpjExists) {
        throw Exception('CNPJ já cadastrado em outro fornecedor');
      }

      final supplierData = supplier.toJson();
      supplierData.remove('id');
      supplierData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_collection)
          .doc(supplier.id)
          .update(supplierData);

      return supplier.copyWith(updatedAt: DateTime.now());
    } on FirebaseException catch (e) {
      throw Exception('Erro ao atualizar fornecedor: ${e.message}');
    }
  }

  /// Deleta fornecedor
  Future<void> deleteSupplier(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao deletar fornecedor: ${e.message}');
    }
  }

  /// Busca fornecedores por texto (nome ou CNPJ)
  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      if (query.isEmpty) return await getSuppliers();

      // Remove formatação se for busca por CNPJ
      final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');

      final List<Supplier> allSuppliers = await getSuppliers();

      // Filtra localmente para ter mais flexibilidade na busca
      return allSuppliers.where((supplier) {
        final nameMatch = supplier.name.toLowerCase().contains(
          query.toLowerCase(),
        );
        final cnpjMatch =
            supplier.cnpj.contains(cleanQuery) ||
            supplier.formattedCnpj.contains(query);

        return nameMatch || cnpjMatch;
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Erro na busca: ${e.message}');
    }
  }

  /// Busca fornecedores por status
  Future<List<Supplier>> getSuppliersByStatus(bool isActive) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: isActive)
              .orderBy('name')
              .get();

      return querySnapshot.docs
          .map((doc) => Supplier.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar fornecedores: ${e.message}');
    }
  }

  /// Alterna status do fornecedor
  Future<Supplier> toggleSupplierStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final supplier = await getSupplier(id);
      return supplier!.copyWith(isActive: isActive, updatedAt: DateTime.now());
    } on FirebaseException catch (e) {
      throw Exception('Erro ao alterar status: ${e.message}');
    }
  }

  /// Verifica se CNPJ está disponível
  Future<bool> isCnpjAvailable(String cnpj, {String? excludeId}) async {
    return !(await _cnpjExists(cnpj, excludeId: excludeId));
  }

  /// Stream de fornecedores em tempo real
  Stream<List<Supplier>> suppliersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _supplierFromDoc(doc)).toList(),
        );
  }

  /// Stream de fornecedores ativos em tempo real
  Stream<List<Supplier>> activeSuppliersStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _supplierFromDoc(doc)).toList(),
        );
  }

  /// Conta total de fornecedores
  Future<int> getSuppliersCount() async {
    try {
      final querySnapshot =
          await _firestore.collection(_collection).count().get();

      return querySnapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao contar fornecedores: ${e.message}');
    }
  }

  /// Conta fornecedores ativos
  Future<int> getActiveSuppliersCount() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .count()
              .get();

      return querySnapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao contar fornecedores ativos: ${e.message}');
    }
  }

  /// Busca fornecedor por CNPJ
  Future<Supplier?> getSupplierByCnpj(String cnpj) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('cnpj', isEqualTo: cnpjLimpo)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return _supplierFromDoc(querySnapshot.docs.first);
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar fornecedor por CNPJ: ${e.message}');
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Converte DocumentSnapshot para Supplier
  Supplier _supplierFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return Supplier(
      id: doc.id,
      name: data['name'] as String,
      cnpj: data['cnpj'] as String,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Converte Timestamp do Firestore para DateTime
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  /// Verifica se CNPJ já existe no Firestore
  Future<bool> _cnpjExists(String cnpj, {String? excludeId}) async {
    try {
      final cnpjLimpo = limparCNPJ(cnpj);

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('cnpj', isEqualTo: cnpjLimpo)
              .get();

      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao verificar CNPJ: ${e.message}');
    }
  }

  // ==================== CNPJ UTILITY METHODS ====================

  /// Valida CNPJ usando algoritmo oficial
  static bool validarCNPJ(String cnpj) {
    final cnpjLimpo = limparCNPJ(cnpj);

    if (cnpjLimpo.length != 14) return false;

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpjLimpo)) return false;

    try {
      // Calcula primeiro dígito verificador
      List<int> digits = cnpjLimpo.split('').map(int.parse).toList();
      List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      int sum1 = 0;
      for (int i = 0; i < 12; i++) {
        sum1 += digits[i] * weights1[i];
      }

      int remainder1 = sum1 % 11;
      int digit1 = remainder1 < 2 ? 0 : 11 - remainder1;

      if (digits[12] != digit1) return false;

      // Calcula segundo dígito verificador
      List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      int sum2 = 0;
      for (int i = 0; i < 13; i++) {
        sum2 += digits[i] * weights2[i];
      }

      int remainder2 = sum2 % 11;
      int digit2 = remainder2 < 2 ? 0 : 11 - remainder2;

      return digits[13] == digit2;
    } catch (e) {
      return false;
    }
  }

  /// Formata CNPJ para exibição (XX.XXX.XXX/XXXX-XX)
  static String formatarCNPJ(String cnpj) {
    final cnpjLimpo = limparCNPJ(cnpj);
    if (cnpjLimpo.length != 14) return cnpj;

    return '${cnpjLimpo.substring(0, 2)}.${cnpjLimpo.substring(2, 5)}.${cnpjLimpo.substring(5, 8)}/${cnpjLimpo.substring(8, 12)}-${cnpjLimpo.substring(12, 14)}';
  }

  /// Remove formatação do CNPJ, deixando apenas números
  static String limparCNPJ(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Valida se o CNPJ tem formato correto (14 dígitos)
  static bool _validarFormatoCNPJ(String cnpj) {
    return cnpj.length == 14 && RegExp(r'^\d+$').hasMatch(cnpj);
  }

  void dispose() {
    _httpClient.close();
  }
}

// ==================== EXCEPTION CLASSES ====================

class CNPJException implements Exception {
  final String message;

  CNPJException(this.message);

  @override
  String toString() => message;
}