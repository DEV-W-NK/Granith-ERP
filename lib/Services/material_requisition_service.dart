import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/purchase_service.dart';

class MaterialRequisitionService {
  static const _table = 'material_requisitions';

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

    return row['id'] as String;
  }

  Future<void> updateRequisition(MaterialRequisitionModel req) async {
    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(req.toMap()))
        .eq('id', req.id);
  }

  Future<void> deleteRequisition(String id) async {
    await AppSupabase.client.from(_table).delete().eq('id', id);
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

    final purchaseService = PurchaseService();
    final purchaseIds = <String>[];
    final now = DateTime.now();
    final sector =
        approvalSector?.trim().isNotEmpty == true
            ? approvalSector!.trim()
            : requisition.requesterSector;

    for (final item in requisition.items) {
      final price = itemPrices[item.itemName] ?? 0.0;
      final purchase = Purchase(
        id: '',
        itemId: '',
        itemName: item.itemName,
        supplierId: supplier.id,
        supplierName: supplier.name,
        projectId: requisition.projectId,
        projectName: requisition.projectName,
        deliveryAddress: requisition.projectName,
        quantity: item.quantity,
        totalValue: price,
        status: PurchaseStatus.awaitingApproval,
        purchaseDate: now,
        requisitionId: requisition.id,
        approvalSector: sector,
        quotedBy: createdBy,
        quotedAt: now,
      );

      purchaseIds.add(await purchaseService.addPurchase(purchase));
    }

    await AppSupabase.client
        .from(_table)
        .update({
          'status': RequisitionStatus.purchased.name,
          'purchaseId': purchaseIds.isNotEmpty ? purchaseIds.first : null,
        })
        .eq('id', requisition.id);

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
}
