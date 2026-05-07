import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/viewmodels/itemsviewmodel.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/items/item_form_dialog.dart';

class ItemsPageView extends StatelessWidget {
  final ItemsViewModel? viewModel;
  final Stream<List<Item>>? itemsStream;

  const ItemsPageView({super.key, this.viewModel, this.itemsStream});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemsViewModel>(
      create: (_) => viewModel ?? ItemsViewModel(ItemService()),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: const _ItemsAppBar(),
        body: Column(
          children: [
            const _ItemsSearchHeader(),
            Expanded(child: _ItemsList(itemsStream: itemsStream)),
          ],
        ),
      ),
    );
  }
}

class _ItemsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ItemsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ItemsViewModel>();

    return AppBar(
      title: const Text(
        'Catálogo de Itens',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _AddButton(onTap: () => _openDialog(context, viewModel)),
        ),
      ],
    );
  }

  void _openDialog(
    BuildContext context,
    ItemsViewModel vm, {
    Item? item,
  }) async {
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
    );
    if (result != null) {
      vm.saveItem(result, isUpdate: item != null);
    }
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentGold, Color(0xFFB8941F)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 16,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                if (!compact) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'Novo',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsSearchHeader extends StatelessWidget {
  const _ItemsSearchHeader();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ItemsViewModel>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Pesquisar itens...',
          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.accentGold,
          ),
          filled: true,
          fillColor: AppColors.backgroundDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.borderColor.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentGold,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: viewModel.updateSearch,
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final Stream<List<Item>>? itemsStream;

  const _ItemsList({this.itemsStream});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItemsViewModel>();

    return StreamBuilder<List<Item>>(
      stream: itemsStream ?? ItemService().getItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorState();
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );

        final items = viewModel.filterItems(snapshot.data!);

        if (items.isEmpty)
          return _EmptyState(isSearch: viewModel.searchQuery.isNotEmpty);

        return ListView.separated(
          padding: ResponsiveLayout.pagePadding(
            MediaQuery.sizeOf(context).width,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder:
              (context, index) =>
                  _ItemCard(item: items[index], viewModel: viewModel),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final ItemsViewModel viewModel;

  const _ItemCard({required this.item, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEdit(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _ItemMenu(item: item, viewModel: viewModel),
                        ],
                      ),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      _ItemTags(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) async {
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
    );
    if (result != null) {
      viewModel.saveItem(result, isUpdate: true);
    }
  }
}

class _ItemIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGold.withOpacity(0.2),
            AppColors.accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        color: AppColors.accentGold,
        size: 28,
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final Item item;
  final ItemsViewModel viewModel;
  const _ItemMenu({required this.item, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderColor.withOpacity(0.5)),
        ),
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Editar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.accentRed,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Excluir',
                      style: TextStyle(color: AppColors.accentRed),
                    ),
                  ],
                ),
              ),
            ],
        onSelected: (value) {
          if (value == 'edit') {
            showDialog(
              context: context,
              builder: (context) => ItemFormDialog(item: item),
            ).then((res) {
              if (res != null) viewModel.saveItem(res, isUpdate: true);
            });
          }
          if (value == 'delete') _confirmDelete(context);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Excluir Item',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Deseja excluir "${item.name}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.deleteItem(item.id);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class _ItemTags extends StatelessWidget {
  final Item item;
  const _ItemTags({required this.item});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Tag(
          label: item.unit,
          icon: Icons.straighten_rounded,
          color: Colors.blueGrey,
        ),
        if (item.weight != null)
          _Tag(
            label: '${item.weight} kg',
            icon: Icons.scale_rounded,
            color: Colors.brown,
          ),
        if (item.width != null || item.height != null || item.length != null)
          _Tag(
            label:
                '${item.width ?? "-"}x${item.height ?? "-"}x${item.length ?? "-"} cm',
            icon: Icons.aspect_ratio_rounded,
            color: Colors.indigo,
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Tag({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Nenhum item encontrado' : 'Nenhum item cadastrado',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar itens',
            style: TextStyle(color: AppColors.textMuted.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
