import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/viewmodels/itemsviewmodel.dart';
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
        body: SafeArea(child: _ItemsCatalogBody(itemsStream: itemsStream)),
      ),
    );
  }
}

class _ItemsCatalogBody extends StatefulWidget {
  final Stream<List<Item>>? itemsStream;

  const _ItemsCatalogBody({this.itemsStream});

  @override
  State<_ItemsCatalogBody> createState() => _ItemsCatalogBodyState();
}

class _ItemsCatalogBodyState extends State<_ItemsCatalogBody> {
  late Stream<List<Item>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.itemsStream ?? ItemService().getItemsStream();
  }

  @override
  void didUpdateWidget(covariant _ItemsCatalogBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemsStream != widget.itemsStream) {
      _stream = widget.itemsStream ?? ItemService().getItemsStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItemsViewModel>();

    return StreamBuilder<List<Item>>(
      stream: _stream,
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? const <Item>[];
        final filteredItems =
            snapshot.hasData ? viewModel.filterItems(allItems) : const <Item>[];

        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = ResponsiveLayout.pagePadding(constraints.maxWidth);

            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CatalogHeader(items: allItems),
                  const SizedBox(height: 10),
                  _ItemsToolbar(
                    visibleCount: filteredItems.length,
                    totalCount: allItems.length,
                    onCreate: () => _openItemDialog(context),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        snapshot.hasError
                            ? const _ErrorState()
                            : !snapshot.hasData
                            ? const _LoadingState()
                            : filteredItems.isEmpty
                            ? _EmptyState(
                              isSearch: viewModel.searchQuery.isNotEmpty,
                            )
                            : _ItemsGrid(items: filteredItems),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _openItemDialog(BuildContext context, {Item? item}) async {
  final viewModel = context.read<ItemsViewModel>();
  final result = await showDialog<Item>(
    context: context,
    builder: (context) => ItemFormDialog(item: item),
  );

  if (result != null) {
    await viewModel.saveItem(result, isUpdate: item != null);
  }
}

class _CatalogHeader extends StatelessWidget {
  final List<Item> items;

  const _CatalogHeader({required this.items});

  @override
  Widget build(BuildContext context) {
    final unitCount = items.map((item) => item.unit).toSet().length;
    final freightReady = items.where((item) => item.hasFreightData).length;
    final described = items.where((item) => item.description.isNotEmpty).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ResponsiveLayout.compact;
        final titleBlock = Row(
          children: [
            if (!compact) ...[const _HeaderIcon(), const SizedBox(width: 12)],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catalogo de Itens',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Base para compras, requisicoes, orcamentos e logistica',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final contextChips = [
          _ContextChip(
            icon: Icons.inventory_2_rounded,
            label: '${items.length} itens',
            color: AppColors.accentGold,
          ),
          _ContextChip(
            icon: Icons.straighten_rounded,
            label: '$unitCount unidades',
            color: AppColors.accentBlue,
          ),
          _ContextChip(
            icon: Icons.local_shipping_rounded,
            label: '$freightReady com frete',
            color: AppColors.accentGreen,
          ),
          _ContextChip(
            icon: Icons.description_rounded,
            label: '$described descritos',
            color: AppColors.textSecondary,
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (
                              var index = 0;
                              index < contextChips.length;
                              index++
                            ) ...[
                              contextChips[index],
                              if (index < contextChips.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: contextChips),
                    ],
                  ),
        );
      },
    );
  }
}

class _ItemsToolbar extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final VoidCallback onCreate;

  const _ItemsToolbar({
    required this.visibleCount,
    required this.totalCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ItemsViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ResponsiveLayout.compact;
        final roomy = constraints.maxWidth >= 980;
        final searchField = SizedBox(
          width:
              compact
                  ? double.infinity
                  : roomy
                  ? 430
                  : 340,
          height: 48,
          child: TextField(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por item, descricao ou unidade',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.backgroundDark.withValues(alpha: 0.34),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
            onChanged: viewModel.updateSearch,
          ),
        );

        final countChip = _ResultChip(
          visibleCount: visibleCount,
          totalCount: totalCount,
        );
        final addButton = SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(compact ? 'Novo item' : 'Cadastrar item'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );

        if (compact) {
          return _ToolbarSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: countChip),
                    const SizedBox(width: 10),
                    Expanded(child: addButton),
                  ],
                ),
              ],
            ),
          );
        }

        if (!roomy) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [searchField, countChip, addButton],
          );
        }

        return Row(
          children: [
            searchField,
            const SizedBox(width: 10),
            countChip,
            const Spacer(),
            addButton,
          ],
        );
      },
    );
  }
}

class _ItemsGrid extends StatelessWidget {
  final List<Item> items;

  const _ItemsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1180
                ? 3
                : constraints.maxWidth >= 760
                ? 2
                : 1;

        return GridView.builder(
          key: const ValueKey('items-grid'),
          padding: const EdgeInsets.only(bottom: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: constraints.maxWidth < 420 ? 238 : 218,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ItemCard(item: items[index]),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateFormat('dd/MM/yyyy').format(item.updatedAt);
    final description =
        item.description.isNotEmpty
            ? item.description
            : 'Sem descricao cadastrada para compras e requisicoes.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent:
            item.hasFreightData ? AppColors.accentGreen : AppColors.accentBlue,
      ),
      child: InkWell(
        onTap: () => _openItemDialog(context, item: item),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemIcon(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Atualizado em $updatedAt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _ItemMenu(item: item),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    item.description.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                fontSize: 13,
                height: 1.32,
              ),
            ),
            const Spacer(),
            _ItemContextBar(item: item),
          ],
        ),
      ),
    );
  }
}

class _ItemContextBar extends StatelessWidget {
  final Item item;

  const _ItemContextBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _Tag(
          label: item.unit,
          icon: Icons.straighten_rounded,
          color: AppColors.accentBlue,
        ),
        _Tag(
          label: item.hasFreightData ? 'Frete configurado' : 'Sem frete',
          icon:
              item.hasFreightData
                  ? Icons.local_shipping_rounded
                  : Icons.local_shipping_outlined,
          color:
              item.hasFreightData ? AppColors.accentGreen : AppColors.textMuted,
        ),
        if (item.weight != null)
          _Tag(
            label: '${_formatNumber(item.weight!)} kg',
            icon: Icons.scale_rounded,
            color: AppColors.accentGold,
          ),
        if (item.hasDimensions)
          _Tag(
            label:
                '${_formatNullable(item.width)} x ${_formatNullable(item.height)} x ${_formatNullable(item.length)} cm',
            icon: Icons.aspect_ratio_rounded,
            color: AppColors.purple,
          ),
      ],
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final Item item;

  const _ItemMenu({required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ItemsViewModel>();

    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'Acoes',
        icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
        ),
        itemBuilder:
            (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: _PopupActionLabel(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: _PopupActionLabel(
                  icon: Icons.delete_outline,
                  label: 'Excluir',
                  isDestructive: true,
                ),
              ),
            ],
        onSelected: (value) {
          if (value == 'edit') {
            _openItemDialog(context, item: item);
          }
          if (value == 'delete') {
            _confirmDelete(context, viewModel);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemsViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.98),
            title: const Text(
              'Excluir item?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Deseja excluir "${item.name}" do catalogo?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await viewModel.deleteItem(item.id);
    }
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.20)),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        color: AppColors.accentGold,
        size: 19,
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  final Item item;

  const _ItemIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    final color =
        item.hasFreightData ? AppColors.accentGreen : AppColors.accentGold;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(Icons.inventory_2_rounded, color: color, size: 22),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final int visibleCount;
  final int totalCount;

  const _ResultChip({required this.visibleCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final filtered = visibleCount != totalCount;
    final text =
        filtered ? '$visibleCount de $totalCount itens' : '$totalCount itens';

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.filter_alt_rounded : Icons.inventory_rounded,
            size: 17,
            color: filtered ? AppColors.accentBlue : AppColors.accentGold,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarSurface extends StatelessWidget {
  final Widget child;

  const _ToolbarSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        elevated: false,
      ),
      child: child,
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
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupActionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _PopupActionLabel({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.accentRed : AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentGold),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;

  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _StatePanel(
          icon:
              isSearch
                  ? Icons.manage_search_rounded
                  : Icons.inventory_2_outlined,
          title: isSearch ? 'Nenhum item encontrado' : 'Nenhum item cadastrado',
          message:
              isSearch
                  ? 'Revise os termos da busca ou cadastre um novo item.'
                  : 'Cadastre itens para usar em compras, requisicoes e orcamentos.',
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: const _StatePanel(
          icon: Icons.error_outline_rounded,
          title: 'Erro ao carregar itens',
          message: 'Nao foi possivel sincronizar o catalogo agora.',
          isError: true,
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.accentRed : AppColors.accentGold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

extension on Item {
  bool get hasDimensions => width != null || height != null || length != null;
  bool get hasFreightData => weight != null || hasDimensions;
}

String _formatNullable(double? value) =>
    value == null ? '-' : _formatNumber(value);

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
