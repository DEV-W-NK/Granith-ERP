import 'package:flutter/material.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ItemsViewModel extends ChangeNotifier {
  final ItemService _itemService;

  ItemsViewModel(this._itemService);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  // Filtra a lista baseada na busca local
  List<Item> filterItems(List<Item> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q),
        )
        .toList();
  }

  // Lógica de persistência
  Future<void> saveItem(Item item, {bool isUpdate = false}) async {
    try {
      if (isUpdate) {
        await _itemService.updateItem(item);
        EasyLoading.showSuccess('Item atualizado!');
      } else {
        await _itemService.addItem(item);
        EasyLoading.showSuccess('Item criado!');
      }
    } catch (e) {
      EasyLoading.showError('Erro ao salvar item');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _itemService.deleteItem(id);
      EasyLoading.showSuccess('Item excluído');
    } catch (e) {
      EasyLoading.showError('Erro ao excluir');
    }
  }
}
