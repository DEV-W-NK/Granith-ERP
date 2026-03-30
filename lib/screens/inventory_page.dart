import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  final InventoryService _service = InventoryService();
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Controle de Estoque',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
                icon: Icon(Icons.inventory_2_outlined, size: 18),
                text: 'Estoque'),
            Tab(
                icon: Icon(Icons.warning_amber_outlined, size: 18),
                text: 'Alertas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surfaceDark,
            child: TextField(
              style:
                  const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar material...',
                hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.accentGold, size: 20),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.accentGold)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InventoryList(
                    service: _service,
                    search: _search,
                    lowStockOnly: false),
                _InventoryList(
                    service: _service,
                    search: _search,
                    lowStockOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista ────────────────────────────────────────────────────────────────────

class _InventoryList extends StatelessWidget {
  final InventoryService service;
  final String search;
  final bool lowStockOnly;

  const _InventoryList({
    required this.service,
    required this.search,
    required this.lowStockOnly,
  });

  @override
  Widget build(BuildContext context) {
    final stream = lowStockOnly
        ? service.getLowStockStream()
        : service.getInventoryStream();

    return StreamBuilder<List<InventoryItem>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold));
        }

        var items = snap.data!;

        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          items = items
              .where((i) => i.name.toLowerCase().contains(q))
              .toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  lowStockOnly
                      ? Icons.check_circle_outline
                      : Icons.inventory_2_outlined,
                  size: 52,
                  color: AppColors.textMuted.withOpacity(0.2),
                ),
                const SizedBox(height: 14),
                Text(
                  lowStockOnly
                      ? 'Nenhum item abaixo do mínimo'
                      : 'Estoque vazio',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _InventoryCard(item: items[i], service: service),
        );
      },
    );
  }
}

// ─── Card de item ─────────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final InventoryService service;

  const _InventoryCard(
      {required this.item, required this.service});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy');
    // stockHealthPercent retorna 0–200 (100 = no mínimo exato)
    // dividimos por 100 para obter 0.0–1.0 para a barra
    final healthPct = item.stockHealthPercent / 100;
    final levelPct  = item.minQuantity > 0 ? healthPct : null;
    final barColor = item.isOutOfStock
        ? Colors.redAccent
        : item.isLowStock
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isLowStock
              ? Colors.orangeAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: barColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Nome + metadados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isOutOfStock)
                            _AlertBadge('Zerado', Colors.redAccent)
                          else if (item.isLowStock)
                            _AlertBadge('Baixo', Colors.orangeAccent),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'Mínimo: ${item.minQuantity.toStringAsFixed(0)} ${item.unit}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11),
                          ),
                          if (item.lastEntryDate != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Entrada: ${dateFormat.format(item.lastEntryDate!)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Quantidade
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.quantity.toStringAsFixed(
                          item.quantity % 1 == 0 ? 0 : 1),
                      style: TextStyle(
                        color: barColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(item.unit,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 8),

                // Ações
                Column(
                  children: [
                    _ActionBtn(
                      icon: Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      tooltip: 'Registrar saída',
                      onTap: () => _showWriteOffDialog(context),
                    ),
                    const SizedBox(height: 4),
                    _ActionBtn(
                      icon: Icons.history,
                      color: AppColors.textMuted,
                      tooltip: 'Ver histórico',
                      onTap: () => _showHistory(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de nível
          if (levelPct != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final fill =
                      levelPct.clamp(0.0, 1.0) * constraints.maxWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: 4,
                        width: fill,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showWriteOffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _WriteOffDialog(item: item, service: service),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _MovementHistorySheet(item: item, service: service),
    );
  }
}

// ─── Dialog de saída manual ───────────────────────────────────────────────────

class _WriteOffDialog extends StatefulWidget {
  final InventoryItem item;
  final InventoryService service;
  const _WriteOffDialog(
      {required this.item, required this.service});

  @override
  State<_WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends State<_WriteOffDialog> {
  final _qtyCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        'Saída: ${widget.item.name}',
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Disponível: ${widget.item.quantity} ${widget.item.unit}',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: _dec(
                'Quantidade (${widget.item.unit})',
                Icons.remove_circle_outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec(
                'Motivo / Projeto (opcional)',
                Icons.notes_outlined),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Registrar saída'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final qty =
        double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quantidade inválida'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.service.addOutboundMovement(
        itemId:   widget.item.id,
        itemName: widget.item.name,
        quantity: qty,
        userId:   'manual',
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Saída registrada'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 13),
        prefixIcon:
            Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: AppColors.accentGold),
            borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
      );
}

// ─── Sheet de histórico ───────────────────────────────────────────────────────

class _MovementHistorySheet extends StatelessWidget {
  final InventoryItem item;
  final InventoryService service;

  const _MovementHistorySheet(
      {required this.item, required this.service});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.history,
                    color: AppColors.accentGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Histórico — ${item.name}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: StreamBuilder<List<InventoryMovement>>(
              stream: service.getMovementsStream(itemId: item.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentGold));
                }

                final movements = snap.data!;

                if (movements.isEmpty) {
                  return const Center(
                    child: Text(
                        'Nenhuma movimentação registrada',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13)),
                  );
                }

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(14),
                  itemCount: movements.length,
                  itemBuilder: (_, i) {
                    final m = movements[i];
                    final isIn = m.type.isAdditive;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  m.type.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(m.type.icon,
                                color: m.type.color, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.type.label +
                                      (m.notes != null
                                          ? ' — ${m.notes}'
                                          : ''),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w500),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                Text(
                                  dateFormat.format(m.date),
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIn ? "+" : "−"} ${m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                            style: TextStyle(
                              color: m.type.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _AlertBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AlertBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}