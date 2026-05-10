import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/requisition_quote_model.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/viewmodels/materialrequisitionviewmodel.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/services/requisition_quote_service.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

// O "Miolo" da página
class MaterialRequisitionPageView extends StatefulWidget {
  const MaterialRequisitionPageView({super.key});

  @override
  State<MaterialRequisitionPageView> createState() =>
      _MaterialRequisitionPageViewState();
}

class _MaterialRequisitionPageViewState
    extends State<MaterialRequisitionPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Inicializa os dados via ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialRequisitionViewModel>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MaterialRequisitionViewModel>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > ResponsiveLayout.compact;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: ResponsiveLayout.pagePadding(width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 20),
            _Tabs(
              tabController: _tabController,
              isDesktop: isDesktop,
              viewModel: viewModel,
            ),
            const SizedBox(height: 14),
            Expanded(
              child:
                  viewModel.isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      )
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _RequisitionList(
                            requisitions: viewModel.allRequisitions,
                          ),
                          _RequisitionList(requisitions: viewModel.pending),
                          _RequisitionList(requisitions: viewModel.approved),
                          _RequisitionList(requisitions: viewModel.completed),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPONENTES PRIVADOS ───────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Aqui você pode expandir para o header oficial se já existir em outro arquivo
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisições de Materiais',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        const Text(
          'Acompanhe e gerencie pedidos de materiais para as obras.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  final TabController tabController;
  final bool isDesktop;
  final MaterialRequisitionViewModel viewModel;

  const _Tabs({
    required this.tabController,
    required this.isDesktop,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.accentGold,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        isScrollable: !isDesktop,
        tabs: [
          Tab(text: 'Todas (${viewModel.allRequisitions.length})'),
          Tab(text: 'Pendentes (${viewModel.pendingCount})'),
          const Tab(text: 'Aprovadas'),
          const Tab(text: 'Concluídas'),
        ],
      ),
    );
  }
}

class _RequisitionList extends StatelessWidget {
  final List<MaterialRequisitionModel> requisitions;
  const _RequisitionList({required this.requisitions});

  @override
  Widget build(BuildContext context) {
    if (requisitions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma requisição nesta categoria.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      itemCount: requisitions.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (_, i) => _CardWrapper(requisition: requisitions[i]),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final MaterialRequisitionModel requisition;
  const _CardWrapper({required this.requisition});

  @override
  Widget build(BuildContext context) {
    // Aqui você usaria o MaterialRequisitionCard original
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  requisition.projectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusBadge(status: requisition.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requisition.itemsSummary, // Assumindo que existe na model
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniInfo(
                icon: Icons.person_outline,
                label: requisition.requesterName,
              ),
              _MiniInfo(
                icon: Icons.priority_high_outlined,
                label: 'Prioridade ${requisition.priority}',
              ),
              OutlinedButton.icon(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (_) => _RequisitionQuotesDialog(
                            requisition: requisition,
                          ),
                    ),
                icon: const Icon(Icons.request_quote_outlined, size: 16),
                label: const Text('Orcar fornecedores'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _RequisitionQuotesDialog extends StatefulWidget {
  final MaterialRequisitionModel requisition;

  const _RequisitionQuotesDialog({required this.requisition});

  @override
  State<_RequisitionQuotesDialog> createState() =>
      _RequisitionQuotesDialogState();
}

class _RequisitionQuotesDialogState extends State<_RequisitionQuotesDialog> {
  final _quoteService = RequisitionQuoteService();
  final _supplierService = SupplierService();
  final _totalCtrl = TextEditingController();
  final _freightCtrl = TextEditingController();
  final _deliveryDaysCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late Future<List<Supplier>> _suppliersFuture;
  Supplier? _selectedSupplier;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _suppliersFuture = _supplierService.getSuppliers();
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _freightCtrl.dispose();
    _deliveryDaysCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _notesCtrl.dispose();
    _supplierService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Row(
        children: [
          const Icon(Icons.request_quote_outlined, color: AppColors.accentGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Orcamentos da requisicao',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: math.min(920.0, size.width * 0.90),
        height: math.min(640.0, size.height * 0.78),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            final form = _buildQuoteForm();
            final quotes = _buildQuotesList();

            if (!desktop) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    form,
                    const SizedBox(height: 14),
                    SizedBox(height: 360, child: quotes),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 330, child: form),
                const SizedBox(width: 16),
                Expanded(child: quotes),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildQuoteForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.requisition.projectName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.requisition.itemsSummary,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _ItemsSummary(items: widget.requisition.items),
            const SizedBox(height: 16),
            FutureBuilder<List<Supplier>>(
              future: _suppliersFuture,
              builder: (context, snapshot) {
                final suppliers = snapshot.data ?? const <Supplier>[];
                if (_selectedSupplier == null && suppliers.isNotEmpty) {
                  _selectedSupplier = suppliers.first;
                }

                return DropdownButtonFormField<Supplier>(
                  key: ValueKey(_selectedSupplier?.id ?? 'no-supplier'),
                  initialValue:
                      suppliers.contains(_selectedSupplier)
                          ? _selectedSupplier
                          : null,
                  isExpanded: true,
                  dropdownColor: AppColors.secondaryDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _quoteDecoration(
                    'Fornecedor cotado',
                    Icons.store_outlined,
                  ),
                  items:
                      suppliers
                          .map(
                            (supplier) => DropdownMenuItem(
                              value: supplier,
                              child: Text(
                                supplier.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (supplier) {
                    setState(() => _selectedSupplier = supplier);
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _quoteDecoration(
                'Valor dos materiais',
                Icons.attach_money,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _freightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _quoteDecoration('Frete', Icons.local_shipping),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _deliveryDaysCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _quoteDecoration(
                'Prazo em dias',
                Icons.event_available_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _paymentTermsCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _quoteDecoration(
                'Condicao de pagamento',
                Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _quoteDecoration(
                'Observacoes de negociacao',
                Icons.sticky_note_2_outlined,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addQuote,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.add_card_outlined),
                label: const Text('Adicionar cotacao'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesList() {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return StreamBuilder<List<RequisitionSupplierQuote>>(
      stream: _quoteService.watchByRequisition(widget.requisition.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        }

        final quotes = snapshot.data!;
        final best = quotes.isEmpty ? 0 : quotes.first.negotiatedTotal;
        final average =
            quotes.isEmpty
                ? 0
                : quotes.fold<double>(
                      0,
                      (total, quote) => total + quote.negotiatedTotal,
                    ) /
                    quotes.length;
        final selected = quotes.where((quote) => quote.isSelected).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuoteMetric(
                  label: 'Cotacoes',
                  value: quotes.length.toString(),
                  icon: Icons.request_quote_outlined,
                ),
                _QuoteMetric(
                  label: 'Melhor preco',
                  value: quotes.isEmpty ? '-' : currency.format(best),
                  icon: Icons.trending_down_outlined,
                  color: AppColors.accentGreen,
                ),
                _QuoteMetric(
                  label: 'Media',
                  value: quotes.isEmpty ? '-' : currency.format(average),
                  icon: Icons.analytics_outlined,
                ),
                if (selected.isNotEmpty)
                  _QuoteMetric(
                    label: 'Selecionado',
                    value: selected.first.supplierName,
                    icon: Icons.verified_outlined,
                    color: AppColors.accentGold,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  quotes.isEmpty
                      ? const _QuotesEmptyState()
                      : ListView.separated(
                        itemCount: quotes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return _QuoteCard(
                            quote: quote,
                            rank: index + 1,
                            onSelect: () => _selectQuote(quote),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addQuote() async {
    final supplier = _selectedSupplier;
    final total = _parseDecimal(_totalCtrl.text);
    final freight = _parseDecimal(_freightCtrl.text);

    if (supplier == null) {
      _showSnack('Cadastre ou selecione um fornecedor antes de cotar.', true);
      return;
    }
    if (total <= 0) {
      _showSnack('Informe o valor dos materiais.', true);
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await _quoteService.addQuote(
        RequisitionSupplierQuote(
          id: '',
          requisitionId: widget.requisition.id,
          supplierId: supplier.id,
          supplierName: supplier.name,
          totalValue: total,
          freightValue: freight,
          deliveryDays: int.tryParse(_deliveryDaysCtrl.text.trim()) ?? 0,
          paymentTerms: _paymentTermsCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          quoteItems:
              widget.requisition.items.map((item) => item.toMap()).toList(),
          quotedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _totalCtrl.clear();
      _freightCtrl.clear();
      _deliveryDaysCtrl.clear();
      _paymentTermsCtrl.clear();
      _notesCtrl.clear();
      _showSnack('Cotacao registrada para comparacao.', false);
    } catch (e) {
      _showSnack('Erro ao salvar cotacao: $e', true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectQuote(RequisitionSupplierQuote quote) async {
    try {
      await _quoteService.selectQuote(widget.requisition.id, quote.id);
      if (!mounted) return;
      _showSnack('Fornecedor selecionado como melhor negociacao.', false);
    } catch (e) {
      _showSnack('Erro ao selecionar cotacao: $e', true);
    }
  }

  void _showSnack(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.accentRed : AppColors.accentGreen,
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final RequisitionSupplierQuote quote;
  final int rank;
  final VoidCallback onSelect;

  const _QuoteCard({
    required this.quote,
    required this.rank,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            quote.isSelected
                ? AppColors.accentGold.withValues(alpha: 0.10)
                : AppColors.primaryDark.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              quote.isSelected
                  ? AppColors.accentGold.withValues(alpha: 0.55)
                  : AppColors.borderColor.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rank.toString(),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quote.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _QuoteStatusBadge(status: quote.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuoteMetric(
                label: 'Total negociado',
                value: currency.format(quote.negotiatedTotal),
                icon: Icons.payments_outlined,
                color: AppColors.accentGold,
              ),
              _QuoteMetric(
                label: 'Materiais',
                value: currency.format(quote.totalValue),
                icon: Icons.inventory_2_outlined,
              ),
              _QuoteMetric(
                label: 'Frete',
                value: currency.format(quote.freightValue),
                icon: Icons.local_shipping,
              ),
              if (quote.deliveryDays > 0)
                _QuoteMetric(
                  label: 'Prazo',
                  value: '${quote.deliveryDays} dias',
                  icon: Icons.event_available_outlined,
                ),
            ],
          ),
          if (quote.paymentTerms.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Pagamento: ${quote.paymentTerms}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (quote.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              quote.notes.trim(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniInfo(
                icon: Icons.schedule_outlined,
                label: dateFormat.format(quote.quotedAt),
              ),
              if (!quote.isSelected)
                OutlinedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: const Text('Selecionar melhor fornecedor'),
                )
              else
                const _MiniInfo(
                  icon: Icons.verified_outlined,
                  label: 'Melhor negociacao selecionada',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsSummary extends StatelessWidget {
  final List<RequisitionItem> items;

  const _ItemsSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'Sem itens informados.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit} - ${item.itemName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _QuoteMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _QuoteMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor.withValues(alpha: 0.78),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteStatusBadge extends StatelessWidget {
  final RequisitionQuoteStatus status;

  const _QuoteStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RequisitionQuoteStatus.selected => AppColors.accentGold,
      RequisitionQuoteStatus.rejected => AppColors.accentRed,
      RequisitionQuoteStatus.sent => AppColors.accentBlue,
      RequisitionQuoteStatus.draft => AppColors.textMuted,
      RequisitionQuoteStatus.received => AppColors.accentGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuotesEmptyState extends StatelessWidget {
  const _QuotesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.request_quote_outlined,
            color: AppColors.textMuted,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            'Nenhuma cotacao registrada',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Adicione fornecedores para comparar preco, frete, prazo e condicao.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

InputDecoration _quoteDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textMuted),
    prefixIcon: Icon(icon, color: AppColors.accentGold, size: 18),
    filled: true,
    fillColor: AppColors.backgroundDark.withValues(alpha: 0.45),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.borderColor.withValues(alpha: 0.7),
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.accentGold),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

double _parseDecimal(String value) {
  final normalized = value.trim();
  if (normalized.contains(',')) {
    return double.tryParse(
          normalized.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }
  return double.tryParse(normalized) ?? 0;
}

class _StatusBadge extends StatelessWidget {
  final RequisitionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.accentGold;
    String label = status.toString().split('.').last;

    if (status == RequisitionStatus.approved) color = AppColors.accentGreen;
    if (status == RequisitionStatus.rejected) color = AppColors.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
