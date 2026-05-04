import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/inventory_service.dart';

class FakeInventoryService extends InventoryService {
  FakeInventoryService() : super();

  Object? outboundError;
  Map<String, dynamic>? lastOutboundPayload;
  Purchase? lastDeliveredPurchase;
  String? lastDeliveryReceivedBy;
  Object? processDeliveryError;

  @override
  Future<void> addOutboundMovement({
    required String itemId,
    required String itemName,
    required double quantity,
    required String userId,
    String? projectId,
    String? projectName,
    String? notes,
  }) async {
    if (outboundError != null) {
      throw outboundError!;
    }

    lastOutboundPayload = {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'userId': userId,
      'projectId': projectId,
      'projectName': projectName,
      'notes': notes,
    };
  }

  @override
  Future<void> processPurchaseDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    if (processDeliveryError != null) {
      throw processDeliveryError!;
    }

    lastDeliveredPurchase = purchase;
    lastDeliveryReceivedBy = receivedBy;
  }
}
