import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/requisition_quote_model.dart';

class RequisitionQuoteService {
  static const _table = 'material_requisition_supplier_quotes';

  Stream<List<RequisitionSupplierQuote>> watchByRequisition(
    String requisitionId,
  ) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('requisitionId', requisitionId)
        .order('totalValue', ascending: true)
        .map(_rowsToQuotes);
  }

  Future<List<RequisitionSupplierQuote>> fetchByRequisition(
    String requisitionId,
  ) async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .eq('requisitionId', requisitionId)
        .order('totalValue', ascending: true);
    return _rowsToQuotes(response as List);
  }

  Future<String> addQuote(RequisitionSupplierQuote quote) async {
    final payload = DbValue.normalizeMap(quote.toMap());
    if ((payload['id'] as String?)?.isEmpty == true) {
      payload.remove('id');
    }

    final row =
        await AppSupabase.client
            .from(_table)
            .insert(payload)
            .select('id')
            .single();
    return row['id'] as String;
  }

  Future<void> updateQuote(RequisitionSupplierQuote quote) async {
    final payload = DbValue.normalizeMap(quote.toMap())..remove('id');
    await AppSupabase.client.from(_table).update(payload).eq('id', quote.id);
  }

  Future<void> selectQuote(String requisitionId, String quoteId) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'isSelected': false,
          'status': RequisitionQuoteStatus.rejected.name,
        })
        .eq('requisitionId', requisitionId)
        .neq('id', quoteId);

    await AppSupabase.client
        .from(_table)
        .update({
          'isSelected': true,
          'status': RequisitionQuoteStatus.selected.name,
        })
        .eq('id', quoteId);
  }

  List<RequisitionSupplierQuote> _rowsToQuotes(List<dynamic> rows) {
    final quotes =
        rows
            .map(
              (row) => RequisitionSupplierQuote.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();
    quotes.sort((a, b) => a.negotiatedTotal.compareTo(b.negotiatedTotal));
    return quotes;
  }
}
