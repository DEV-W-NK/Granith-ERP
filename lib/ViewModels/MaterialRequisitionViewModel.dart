import 'package:flutter/material.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';

class MaterialRequisitionViewModel extends ChangeNotifier {
  final MaterialRequisitionController _controller;
  bool _initialized = false;

  MaterialRequisitionViewModel(this._controller);

  // Inicializa o controller através do ViewModel
  void init() {
    if (_initialized) return;
    _initialized = true;

    _controller.init();
    _controller.addListener(notifyListeners);
  }

  // Getters para facilitar o acesso aos dados filtrados
  bool get isLoading => _controller.isLoading;
  List<MaterialRequisitionModel> get allRequisitions =>
      _controller.requisitions;
  List<MaterialRequisitionModel> get pending => _controller.pending;
  List<MaterialRequisitionModel> get approved => _controller.approved;

  List<MaterialRequisitionModel> get completed {
    return _controller.requisitions
        .where(
          (r) =>
              r.status == RequisitionStatus.purchased ||
              r.status == RequisitionStatus.rejected ||
              r.status == RequisitionStatus.delivered,
        )
        .toList();
  }

  int get pendingCount => _controller.pendingCount;

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
