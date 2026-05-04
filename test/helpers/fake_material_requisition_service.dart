import 'dart:async';

import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/material_requisition_service.dart';

class FakeMaterialRequisitionService extends MaterialRequisitionService {
  FakeMaterialRequisitionService({
    List<MaterialRequisitionModel>? initialRequisitions,
  }) : _controller =
           StreamController<List<MaterialRequisitionModel>>.broadcast(),
       super() {
    if (initialRequisitions != null) {
      _requisitions = List<MaterialRequisitionModel>.from(initialRequisitions);
    }
  }

  final StreamController<List<MaterialRequisitionModel>> _controller;
  List<MaterialRequisitionModel> _requisitions = <MaterialRequisitionModel>[];
  Object? streamError;
  Object? addError;
  Object? approveError;
  Object? rejectError;
  Object? convertError;
  MaterialRequisitionModel? lastAdded;
  MaterialRequisitionModel? lastApproved;
  MaterialRequisitionModel? lastRejected;
  Map<String, dynamic>? lastConvertPayload;
  List<String> nextPurchaseIds = ['purchase-1'];

  @override
  Stream<List<MaterialRequisitionModel>> getRequisitions() {
    if (streamError != null) {
      return Stream<List<MaterialRequisitionModel>>.error(streamError!);
    }

    Future<void>.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(List<MaterialRequisitionModel>.from(_requisitions));
      }
    });
    return _controller.stream;
  }

  void emit(List<MaterialRequisitionModel> requisitions) {
    _requisitions = List<MaterialRequisitionModel>.from(requisitions);
    if (!_controller.isClosed) {
      _controller.add(List<MaterialRequisitionModel>.from(_requisitions));
    }
  }

  @override
  Future<String> addRequisition(MaterialRequisitionModel req) async {
    if (addError != null) {
      throw addError!;
    }

    lastAdded = req;
    final created = req.copyWith(id: req.id.isEmpty ? 'req-created' : req.id);
    _requisitions.add(created);
    emit(_requisitions);
    return created.id;
  }

  @override
  Future<void> approve({
    required MaterialRequisitionModel requisition,
    required String approvedBy,
    required String approvedByName,
  }) async {
    if (approveError != null) {
      throw approveError!;
    }

    lastApproved = requisition;
  }

  @override
  Future<void> reject({
    required MaterialRequisitionModel requisition,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    if (rejectError != null) {
      throw rejectError!;
    }

    lastRejected = requisition;
  }

  @override
  Future<List<String>> convertToPurchase({
    required MaterialRequisitionModel requisition,
    required Supplier supplier,
    required String createdBy,
    required Map<String, double> itemPrices,
  }) async {
    if (convertError != null) {
      throw convertError!;
    }

    lastConvertPayload = {
      'requisition': requisition,
      'supplier': supplier,
      'createdBy': createdBy,
      'itemPrices': itemPrices,
    };
    return List<String>.from(nextPurchaseIds);
  }

  Future<void> disposeController() => _controller.close();
}
