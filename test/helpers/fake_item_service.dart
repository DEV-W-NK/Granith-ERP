import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/services/item_service.dart';

class FakeItemService extends ItemService {
  FakeItemService({List<Item>? initialItems})
    : _items = List<Item>.from(initialItems ?? const <Item>[]);

  final List<Item> _items;
  Object? addError;
  Object? updateError;
  Object? deleteError;
  Item? lastAddedItem;
  Item? lastUpdatedItem;
  String? lastDeletedId;
  String createdId = 'item-created';

  @override
  Future<String> addItem(Item item) async {
    if (addError != null) {
      throw addError!;
    }

    lastAddedItem = item;
    _items.add(item.copyWith(id: createdId));
    return createdId;
  }

  @override
  Future<void> updateItem(Item item) async {
    if (updateError != null) {
      throw updateError!;
    }

    lastUpdatedItem = item;
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    if (deleteError != null) {
      throw deleteError!;
    }

    lastDeletedId = id;
    _items.removeWhere((entry) => entry.id == id);
  }
}
