import 'package:flutter/material.dart';
import 'package:project_granith/widgets/items/item_form_dialog.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemService _itemService = ItemService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // AppBar customizada para combinar com o tema
      appBar: AppBar(
        title: const Text(
          'Catálogo de Itens',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Botão de Adicionar com Gradiente
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGold, Color(0xFFB8941F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                onTap: () => _openItemDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.primaryDark, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Novo',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header de Pesquisa Fixo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Pesquisar itens...',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentGold),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ) 
                  : null,
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Lista de Itens
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _itemService.getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.accentRed),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar itens', style: TextStyle(color: AppColors.textMuted.withOpacity(0.8))),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
                }

                var items = snapshot.data!;
                
                // Filtro local
                if (_searchQuery.isNotEmpty) {
                  items = items.where((item) => 
                    item.name.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
                          ),
                          child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'Nenhum item encontrado para a busca' 
                            : 'Nenhum item cadastrado', 
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _openItemDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Cadastrar Primeiro Item'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentGold,
                              side: const BorderSide(color: AppColors.accentGold),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          )
                        ]
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openItemDialog(context, item: item),
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.accentGold.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / Ícone do Item
                Container(
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
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.accentGold, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Informações do Item
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Botão de Menu (Ações)
                          SizedBox(
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
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                                      SizedBox(width: 12),
                                      Text('Editar', style: TextStyle(color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: AppColors.accentRed),
                                      SizedBox(width: 12),
                                      Text('Excluir', style: TextStyle(color: AppColors.accentRed)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') _openItemDialog(context, item: item);
                                if (value == 'delete') _confirmDelete(item);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Tags Modernas
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildModernTag(
                            label: item.unit,
                            icon: Icons.straighten_rounded,
                            color: Colors.blueGrey,
                          ),
                          if (item.weight != null)
                            _buildModernTag(
                              label: '${item.weight} kg',
                              icon: Icons.scale_rounded,
                              color: Colors.brown,
                            ),
                          if (item.width != null || item.height != null || item.length != null)
                            _buildModernTag(
                              label: _formatDimensions(item),
                              icon: Icons.aspect_ratio_rounded,
                              color: Colors.indigo,
                            ),
                        ],
                      ),
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

  // Helper para formatar dimensões de forma compacta
  String _formatDimensions(Item item) {
    final w = item.width?.toStringAsFixed(0) ?? '-';
    final h = item.height?.toStringAsFixed(0) ?? '-';
    final l = item.length?.toStringAsFixed(0) ?? '-';
    return '${w}x${h}x$l cm';
  }

  // Widget de Tag Estilizada
  Widget _buildModernTag({required String label, required IconData icon, required Color color}) {
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
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _openItemDialog(BuildContext context, {Item? item}) async {
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
    );

    if (result != null) {
      try {
        if (item == null) {
          await _itemService.addItem(result);
          EasyLoading.showSuccess('Item criado!');
        } else {
          await _itemService.updateItem(result.copyWith(id: item.id));
          EasyLoading.showSuccess('Item atualizado!');
        }
      } catch (e) {
        EasyLoading.showError('Erro ao salvar item');
      }
    }
  }

  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentRed, size: 24),
            SizedBox(width: 12),
            Text('Excluir Item', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir "${item.name}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _itemService.deleteItem(item.id);
                EasyLoading.showSuccess('Item excluído');
              } catch (e) {
                EasyLoading.showError('Erro ao excluir');
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}