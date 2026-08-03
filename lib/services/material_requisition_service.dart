import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/requisition_quote_model.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/archive_service.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';

class MaterialRequisitionService {
  static const _table = 'material_requisitions';
  final ArchiveService _archiveService = ArchiveService();

  MaterialRequisitionService();

  Stream<List<MaterialRequisitionModel>> getRequisitions() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('requestDate', ascending: false)
        .map(_rowsToRequisitions);
  }

  Stream<List<MaterialRequisitionModel>> getByProject(String projectId) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('projectId', projectId)
        .order('requestDate', ascending: false)
        .map(_rowsToRequisitions);
  }

  Stream<List<MaterialRequisitionModel>> getByStatus(RequisitionStatus status) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('status', status.name)
        .order('requestDate', ascending: false)
        .map(_rowsToRequisitions);
  }

  Future<String> addRequisition(MaterialRequisitionModel req) async {
    final row =
        await AppSupabase.client
            .from(_table)
            .insert(DbValue.normalizeMap(req.toMap()))
            .select('id')
            .single();

    final id = row['id'] as String;
    _notifyChanged();
    unawaited(MobilePushDispatchService.dispatchPending());
    return id;
  }

  Future<void> updateRequisition(MaterialRequisitionModel req) async {
    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(req.toMap()))
        .eq('id', req.id);
    _notifyChanged();
    unawaited(MobilePushDispatchService.dispatchPending());
  }

  Future<void> deleteRequisition(String id) async {
    await _archiveService.archive(
      table: _table,
      id: id,
      reason: 'Requisicao removida pelo usuario.',
    );
    _notifyChanged();
  }

  Future<void> approve({
    required MaterialRequisitionModel requisition,
    required String approvedBy,
    required String approvedByName,
  }) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'status': RequisitionStatus.approved.name,
          'approvedBy': approvedBy,
          'approvedByName': approvedByName,
          'approvedAt': DbValue.toPrimitive(DateTime.now()),
          'rejectionReason': null,
        })
        .eq('id', requisition.id);
    _notifyChanged();
    unawaited(MobilePushDispatchService.dispatchPending());
  }

  Future<void> reject({
    required MaterialRequisitionModel requisition,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Informe o motivo da rejeicao.');
    }

    await AppSupabase.client
        .from(_table)
        .update({
          'status': RequisitionStatus.rejected.name,
          'approvedBy': rejectedBy,
          'approvedByName': rejectedByName,
          'approvedAt': DbValue.toPrimitive(DateTime.now()),
          'rejectionReason': reason.trim(),
        })
        .eq('id', requisition.id);
    _notifyChanged();
    unawaited(MobilePushDispatchService.dispatchPending());
  }

  Future<List<String>> convertToPurchase({
    required MaterialRequisitionModel requisition,
    required Supplier supplier,
    required String createdBy,
    required Map<String, double> itemPrices,
    String? approvalSector,
  }) async {
    if (requisition.status != RequisitionStatus.pending &&
        requisition.status != RequisitionStatus.approved) {
      throw Exception(
        'A requisicao precisa estar pendente ou aprovada para gerar o orcamento de compra.',
      );
    }

    final response = await AppSupabase.client.rpc(
      'convert_requisition_to_purchases_atomic',
      params: {
        'p_requisition_id': requisition.id,
        'p_supplier_id': supplier.id,
        'p_supplier_name': supplier.name,
        'p_item_prices': itemPrices,
        'p_created_by': createdBy,
        'p_approval_sector': approvalSector,
      },
    );
    final purchaseIds = _rpcTextArray(response);

    _notifyChanged(extraScopes: const [AppDataRefreshBus.purchases]);
    unawaited(MobilePushDispatchService.dispatchPending());
    return purchaseIds;
  }

  Future<List<String>> convertQuoteToPurchaseOrder({
    required MaterialRequisitionModel requisition,
    required RequisitionSupplierQuote quote,
    required String createdBy,
    String? createdByName,
    String? approvalSector,
  }) async {
    if (requisition.status == RequisitionStatus.rejected ||
        requisition.status == RequisitionStatus.delivered) {
      throw Exception(
        'A requisicao precisa estar pendente ou aprovada para virar pedido de compra.',
      );
    }
    if (quote.requisitionId != requisition.id) {
      throw Exception('A cotacao selecionada nao pertence a esta requisicao.');
    }
    if (quote.id.trim().isEmpty) {
      throw Exception('A cotacao precisa estar salva antes de gerar a compra.');
    }
    if (quote.supplierName.trim().isEmpty) {
      throw Exception('A cotacao precisa ter um fornecedor informado.');
    }
    if (quote.negotiatedTotal <= 0) {
      throw Exception(
        'A cotacao precisa ter um valor negociado maior que zero.',
      );
    }

    final response = await AppSupabase.client.rpc(
      'convert_quote_to_purchases_atomic',
      params: {
        'p_requisition_id': requisition.id,
        'p_quote_id': quote.id,
        'p_created_by': createdBy,
        'p_created_by_name': createdByName,
        'p_approval_sector': approvalSector,
      },
    );
    final purchaseIds = _rpcTextArray(response);

    _notifyChanged(
      extraScopes: const [
        AppDataRefreshBus.purchases,
        AppDataRefreshBus.requisitionQuotes,
      ],
    );
    unawaited(MobilePushDispatchService.dispatchPending());
    return purchaseIds;
  }

  List<MaterialRequisitionModel> _rowsToRequisitions(List<dynamic> rows) {
    return rows
        .map((row) => _rowToRequisition(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  MaterialRequisitionModel _rowToRequisition(Map<String, dynamic> row) {
    return MaterialRequisitionModel.fromMap(row, row['id'] as String? ?? '');
  }

  List<String> _rpcTextArray(dynamic response) {
    if (response is! List) return const <String>[];
    return response
        .map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList();
  }

  void _notifyChanged({List<String> extraScopes = const []}) {
    AppDataRefreshBus.instance.notify(
      scopes: [AppDataRefreshBus.materialRequisitions, ...extraScopes],
      source: 'MaterialRequisitionService',
    );
  }
}
