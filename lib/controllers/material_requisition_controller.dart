import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/material_requisition_service.dart';

class MaterialRequisitionController extends ChangeNotifier {
  final MaterialRequisitionService _service;

  MaterialRequisitionController({MaterialRequisitionService? service})
    : _service = service ?? MaterialRequisitionService();

  List<MaterialRequisitionModel> _requisitions = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<MaterialRequisitionModel>>? _sub;

  List<MaterialRequisitionModel> get requisitions => _requisitions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MaterialRequisitionModel> get pending =>
      _requisitions
          .where((r) => r.status == RequisitionStatus.pending)
          .toList();
  List<MaterialRequisitionModel> get approved =>
      _requisitions
          .where((r) => r.status == RequisitionStatus.approved)
          .toList();
  List<MaterialRequisitionModel> get highPriority =>
      _requisitions
          .where(
            (r) =>
                r.priority == 'Alta' && r.status == RequisitionStatus.pending,
          )
          .toList();
  int get pendingCount => pending.length;

  void init() {
    _setLoading(true);
    _sub?.cancel();
    _sub = _service.getRequisitions().listen(
      (list) {
        _requisitions = list;
        _setLoading(false);
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  Future<void> addRequisition(MaterialRequisitionModel req) async {
    try {
      await _service.addRequisition(req);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approve({
    required MaterialRequisitionModel requisition,
    required String approvedBy,
    required String approvedByName,
  }) async {
    try {
      await _service.approve(
        requisition: requisition,
        approvedBy: approvedBy,
        approvedByName: approvedByName,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reject({
    required MaterialRequisitionModel requisition,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    try {
      await _service.reject(
        requisition: requisition,
        rejectedBy: rejectedBy,
        rejectedByName: rejectedByName,
        reason: reason,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<String>> convertToPurchase({
    required MaterialRequisitionModel requisition,
    required Supplier supplier,
    required String createdBy,
    required Map<String, double> itemPrices,
  }) async {
    try {
      return await _service.convertToPurchase(
        requisition: requisition,
        supplier: supplier,
        createdBy: createdBy,
        itemPrices: itemPrices,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
