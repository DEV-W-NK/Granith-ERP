import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/requisition_quote_model.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';
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
    await AppSupabase.client.from(_table).delete().eq('id', id);
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

    final existingPurchaseIds = await _existingPurchaseIdsForRequisition(
      requisition.id,
    );
    if (existingPurchaseIds.isNotEmpty) {
      await _selectQuote(quote.requisitionId, quote.id);
      await _markRequisitionPurchased(
        requisition.id,
        existingPurchaseIds.first,
      );
      _notifyChanged(
        extraScopes: const [
          AppDataRefreshBus.purchases,
          AppDataRefreshBus.requisitionQuotes,
        ],
      );
      unawaited(MobilePushDispatchService.dispatchPending());
      return existingPurchaseIds;
    }

    final now = DateTime.now();
    final quoteItems = _quoteItemsForPurchase(requisition, quote);
    if (quoteItems.isEmpty) {
      throw Exception('A requisicao precisa ter pelo menos um item.');
    }
    final lineValues = _allocateQuoteTotal(quoteItems, quote.negotiatedTotal);
    final sector =
        approvalSector?.trim().isNotEmpty == true
            ? approvalSector!.trim()
            : requisition.requesterSector;
    final expectedDeliveryDate =
        quote.deliveryDays > 0
            ? now.add(Duration(days: quote.deliveryDays))
            : null;

    final purchases = <Purchase>[];
    for (var index = 0; index < quoteItems.length; index += 1) {
      final item = quoteItems[index];
      final itemName = _stringFromItem(item, 'itemName').trim();
      purchases.add(
        Purchase(
          id: '',
          itemId: _firstNonEmptyString(item, const [
            'itemId',
            'item_id',
            'inventoryItemId',
            'catalogItemId',
          ]),
          itemName: itemName.isEmpty ? 'Item da requisicao' : itemName,
          supplierId: quote.supplierId ?? '',
          supplierName: quote.supplierName,
          projectId: requisition.projectId,
          projectName: requisition.projectName,
          deliveryAddress: requisition.projectName,
          quantity: _numberFromItem(item, 'quantity', fallback: 1),
          totalValue: lineValues[index],
          status: PurchaseStatus.awaitingApproval,
          purchaseDate: now,
          expectedDeliveryDate: expectedDeliveryDate,
          requisitionId: requisition.id,
          approvalSector: sector,
          quotedBy: createdBy,
          quotedByName: createdByName?.trim(),
          quotedAt: quote.quotedAt,
          notes: _purchaseNotesFromQuote(quote),
        ),
      );
    }

    final rows = await AppSupabase.client
        .from('purchases')
        .insert(
          purchases
              .map((purchase) => DbValue.normalizeMap(purchase.toMap()))
              .toList(),
        )
        .select('id');
    final purchaseIds =
        (rows as List)
            .map((row) => (row as Map)['id']?.toString() ?? '')
            .where((id) => id.trim().isNotEmpty)
            .toList();

    await _selectQuote(quote.requisitionId, quote.id);
    await _markRequisitionPurchased(
      requisition.id,
      purchaseIds.isNotEmpty ? purchaseIds.first : null,
    );

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

  Future<List<String>> _existingPurchaseIdsForRequisition(
    String requisitionId,
  ) async {
    final response = await AppSupabase.client
        .from('purchases')
        .select('id')
        .eq('requisitionId', requisitionId)
        .neq('status', PurchaseStatus.cancelled.index)
        .order('purchaseDate', ascending: false);

    return (response as List)
        .map((row) => (row as Map)['id']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toList();
  }

  Future<void> _selectQuote(String requisitionId, String quoteId) async {
    await AppSupabase.client
        .from('material_requisition_supplier_quotes')
        .update({
          'isSelected': false,
          'status': RequisitionQuoteStatus.rejected.name,
        })
        .eq('requisitionId', requisitionId)
        .neq('id', quoteId);

    await AppSupabase.client
        .from('material_requisition_supplier_quotes')
        .update({
          'isSelected': true,
          'status': RequisitionQuoteStatus.selected.name,
        })
        .eq('id', quoteId);
  }

  Future<void> _markRequisitionPurchased(
    String requisitionId,
    String? purchaseId,
  ) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'status': RequisitionStatus.purchased.name,
          'purchaseId': purchaseId,
        })
        .eq('id', requisitionId);
  }

  List<Map<String, dynamic>> _quoteItemsForPurchase(
    MaterialRequisitionModel requisition,
    RequisitionSupplierQuote quote,
  ) {
    final quoteItems =
        quote.quoteItems
            .where(
              (item) => _stringFromItem(item, 'itemName').trim().isNotEmpty,
            )
            .map(Map<String, dynamic>.from)
            .toList();
    if (quoteItems.isNotEmpty) {
      return quoteItems;
    }

    return requisition.items.map((item) => item.toMap()).toList();
  }

  List<double> _allocateQuoteTotal(
    List<Map<String, dynamic>> items,
    double negotiatedTotal,
  ) {
    if (items.isEmpty) return const <double>[];

    final explicitValues = items.map(_lineTotalFromItem).toList();
    final explicitTotal = explicitValues.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final weights =
        explicitTotal > 0
            ? explicitValues
            : items
                .map((item) => _numberFromItem(item, 'quantity', fallback: 1))
                .map((quantity) => quantity <= 0 ? 1.0 : quantity)
                .toList();
    final weightTotal = weights.fold<double>(0, (sum, value) => sum + value);
    if (weightTotal <= 0) {
      final evenValue = _roundCurrency(negotiatedTotal / items.length);
      return List<double>.filled(items.length, evenValue);
    }

    final allocated = <double>[];
    var runningTotal = 0.0;
    for (var index = 0; index < items.length; index += 1) {
      if (index == items.length - 1) {
        allocated.add(_roundCurrency(negotiatedTotal - runningTotal));
      } else {
        final value = _roundCurrency(
          negotiatedTotal * (weights[index] / weightTotal),
        );
        allocated.add(value);
        runningTotal += value;
      }
    }
    return allocated;
  }

  double _lineTotalFromItem(Map<String, dynamic> item) {
    for (final key in const [
      'totalValue',
      'lineTotal',
      'subtotal',
      'total',
      'priceTotal',
    ]) {
      final value = _numberFromItem(item, key);
      if (value > 0) return value;
    }

    final unitPrice = _firstPositiveNumber(item, const [
      'unitPrice',
      'price',
      'unitValue',
    ]);
    if (unitPrice > 0) {
      return unitPrice * _numberFromItem(item, 'quantity', fallback: 1);
    }

    return 0;
  }

  String _purchaseNotesFromQuote(RequisitionSupplierQuote quote) {
    final parts = <String>[
      'Pedido gerado a partir da cotacao ${quote.id}.',
      if (quote.paymentTerms.trim().isNotEmpty)
        'Condicao: ${quote.paymentTerms.trim()}.',
      if (quote.freightValue > 0)
        'Frete rateado: R\$ ${quote.freightValue.toStringAsFixed(2)}.',
      if (quote.notes.trim().isNotEmpty) quote.notes.trim(),
    ];
    return parts.join('\n');
  }

  String _firstNonEmptyString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = _stringFromItem(item, key).trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  double _firstPositiveNumber(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = _numberFromItem(item, key);
      if (value > 0) return value;
    }
    return 0;
  }

  String _stringFromItem(Map<String, dynamic> item, String key) =>
      item[key]?.toString() ?? '';

  double _numberFromItem(
    Map<String, dynamic> item,
    String key, {
    double fallback = 0,
  }) {
    final value = item[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      final commaIndex = trimmed.lastIndexOf(',');
      final dotIndex = trimmed.lastIndexOf('.');
      final normalized =
          commaIndex > dotIndex
              ? trimmed.replaceAll('.', '').replaceAll(',', '.')
              : trimmed.replaceAll(',', '');
      return double.tryParse(normalized) ?? fallback;
    }
    return fallback;
  }

  double _roundCurrency(double value) => (value * 100).roundToDouble() / 100;

  void _notifyChanged({List<String> extraScopes = const []}) {
    AppDataRefreshBus.instance.notify(
      scopes: [AppDataRefreshBus.materialRequisitions, ...extraScopes],
      source: 'MaterialRequisitionService',
    );
  }
}
