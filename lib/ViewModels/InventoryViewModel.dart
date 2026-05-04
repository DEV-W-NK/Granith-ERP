import 'package:flutter/material.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/services/inventory_service.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryService _service;

  InventoryViewModel(this._service);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  // Filtra a lista baseada na busca
  List<InventoryItem> filterItems(List<InventoryItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  // Atalho para registrar saída
  Future<void> registerOutput({
    required String itemId,
    required String itemName,
    required double quantity,
    String? notes,
  }) async {
    await _service.addOutboundMovement(
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      userId: 'manual_user', // Idealmente viria do Auth
      notes: notes,
    );
  }
}
