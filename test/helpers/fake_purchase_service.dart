import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super();

  String? lastApprovedPurchaseId;
  String? lastApprovedBy;
  String? lastApprovedByName;

  String? lastRejectedPurchaseId;
  String? lastRejectedBy;
  String? lastRejectedByName;
  String? lastRejectionReason;

  String? lastUpdatedStatusId;
  PurchaseStatus? lastUpdatedStatus;

  Purchase? lastConfirmedDeliveryPurchase;
  String? lastReceivedBy;

  Object? approveError;
  Object? rejectError;
  Object? updateStatusError;
  Object? confirmDeliveryError;

  @override
  Future<void> approvePurchase({
    required String purchaseId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    if (approveError != null) {
      throw approveError!;
    }

    lastApprovedPurchaseId = purchaseId;
    lastApprovedBy = approvedBy;
    lastApprovedByName = approvedByName;
  }

  @override
  Future<void> rejectPurchase({
    required String purchaseId,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    if (rejectError != null) {
      throw rejectError!;
    }

    lastRejectedPurchaseId = purchaseId;
    lastRejectedBy = rejectedBy;
    lastRejectedByName = rejectedByName;
    lastRejectionReason = reason;
  }

  @override
  Future<void> updateStatus(String id, PurchaseStatus status) async {
    if (updateStatusError != null) {
      throw updateStatusError!;
    }

    lastUpdatedStatusId = id;
    lastUpdatedStatus = status;
  }

  @override
  Future<void> confirmDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    if (confirmDeliveryError != null) {
      throw confirmDeliveryError!;
    }

    lastConfirmedDeliveryPurchase = purchase;
    lastReceivedBy = receivedBy;
  }
}
