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
import 'package:project_granith/widgets/components/granith_dialog.dart';

enum _RequisitionSort { priority, newest, oldest, project, itemCount }

extension _RequisitionSortLabel on _RequisitionSort {
  String get label => switch (this) {
    _RequisitionSort.priority => 'Prioridade',
    _RequisitionSort.newest => 'Mais recentes',
    _RequisitionSort.oldest => 'Mais antigas',
    _RequisitionSort.project => 'Obra',
    _RequisitionSort.itemCount => 'Mais itens',
  };

  IconData get icon => switch (this) {
    _RequisitionSort.priority => Icons.priority_high_outlined,
    _RequisitionSort.newest => Icons.schedule_outlined,
    _RequisitionSort.oldest => Icons.history_outlined,
    _RequisitionSort.project => Icons.business_outlined,
    _RequisitionSort.itemCount => Icons.inventory_2_outlined,
  };
}

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
  final _searchCtrl = TextEditingController();
  _RequisitionSort _sort = _RequisitionSort.priority;
  String _query = '';

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
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MaterialRequisitionViewModel>();
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isDesktop = width > ResponsiveLayout.compact;
    final compactHeight = size.height < 700;
    final summary = _RequisitionSummary.from(viewModel.allRequisitions);
    final all = _filterAndSort(viewModel.allRequisitions);
    final pending = _filterAndSort(viewModel.pending);
    final approved = _filterAndSort(viewModel.approved);
    final completed = _filterAndSort(viewModel.completed);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: ResponsiveLayout.pagePadding(width),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 10),
                _SummaryFilterRow(
                  showStats: !compactHeight,
                  summary: summary,
                  controller: _searchCtrl,
                  query: _query,
                  sort: _sort,
                  visibleCount: all.length,
                  totalCount: viewModel.allRequisitions.length,
                  onQueryChanged: (value) {
                    setState(() => _query = value.trim());
                  },
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onSortChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                  },
                ),
                const SizedBox(height: 10),
                _Tabs(
                  tabController: _tabController,
                  isDesktop: isDesktop,
                  allCount: all.length,
                  pendingCount: pending.length,
                  approvedCount: approved.length,
                  completedCount: completed.length,
                ),
                const SizedBox(height: 12),
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
                                requisitions: all,
                                emptyLabel:
                                    _query.isEmpty
                                        ? 'Nenhuma requisicao cadastrada.'
                                        : 'Nenhuma requisicao encontrada.',
                              ),
                              _RequisitionList(
                                requisitions: pending,
                                emptyLabel:
                                    _query.isEmpty
                                        ? 'Nao ha requisicoes pendentes.'
                                        : 'Nenhuma pendencia encontrada.',
                              ),
                              _RequisitionList(
                                requisitions: approved,
                                emptyLabel:
                                    _query.isEmpty
                                        ? 'Nao ha requisicoes aprovadas.'
                                        : 'Nenhuma aprovada encontrada.',
                              ),
                              _RequisitionList(
                                requisitions: completed,
                                emptyLabel:
                                    _query.isEmpty
                                        ? 'Nao ha requisicoes concluidas.'
                                        : 'Nenhuma concluida encontrada.',
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

  List<MaterialRequisitionModel> _filterAndSort(
    List<MaterialRequisitionModel> requisitions,
  ) {
    final filtered =
        requisitions
            .where((requisition) => _matchesQuery(requisition))
            .toList();
    filtered.sort(_compareRequisitions);
    return filtered;
  }

  bool _matchesQuery(MaterialRequisitionModel requisition) {
    final normalized = _query.toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack =
        [
          requisition.projectName,
          requisition.requesterName,
          requisition.requesterSector,
          requisition.priority,
          requisition.status.label,
          requisition.itemsSummary,
          ...requisition.items.map((item) => item.itemName),
        ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }

  int _compareRequisitions(
    MaterialRequisitionModel a,
    MaterialRequisitionModel b,
  ) {
    final statusPriority = _statusRank(
      b.status,
    ).compareTo(_statusRank(a.status));
    if (_sort == _RequisitionSort.priority && statusPriority != 0) {
      return statusPriority;
    }

    return switch (_sort) {
      _RequisitionSort.priority => _priorityRank(
        b.priority,
      ).compareTo(_priorityRank(a.priority)),
      _RequisitionSort.newest => b.requestDate.compareTo(a.requestDate),
      _RequisitionSort.oldest => a.requestDate.compareTo(b.requestDate),
      _RequisitionSort.project => a.projectName.toLowerCase().compareTo(
        b.projectName.toLowerCase(),
      ),
      _RequisitionSort.itemCount => b.itemCount.compareTo(a.itemCount),
    };
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
  final int allCount;
  final int pendingCount;
  final int approvedCount;
  final int completedCount;

  const _Tabs({
    required this.tabController,
    required this.isDesktop,
    required this.allCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.35),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        isScrollable: !isDesktop,
        tabs: [
          Tab(text: 'Todas ($allCount)'),
          Tab(text: 'Pendentes ($pendingCount)'),
          Tab(text: 'Aprovadas ($approvedCount)'),
          Tab(text: 'Concluidas ($completedCount)'),
        ],
      ),
    );
  }
}

class _RequisitionList extends StatelessWidget {
  final List<MaterialRequisitionModel> requisitions;
  final String emptyLabel;

  const _RequisitionList({
    required this.requisitions,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (requisitions.isEmpty) {
      return _EmptyState(label: emptyLabel);
    }
    return ListView.separated(
      itemCount: requisitions.length,
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CardWrapper(requisition: requisitions[i]),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final MaterialRequisitionModel requisition;
  const _CardWrapper({required this.requisition});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: requisition.status.color,
        emphasized: requisition.status == RequisitionStatus.pending,
        radius: 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final main = _RequisitionCardMain(
            requisition: requisition,
            dateFormat: dateFormat,
          );
          final actionPanel = _RequisitionActionPanel(
            requisition: requisition,
            onOpenQuotes:
                () => showDialog<void>(
                  context: context,
                  builder:
                      (_) => _RequisitionQuotesDialog(requisition: requisition),
                ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusBadge(status: requisition.status),
                  _PriorityBadge(priority: requisition.priority),
                  if (requisition.status == RequisitionStatus.pending &&
                      _priorityRank(requisition.priority) >= 3)
                    const _SoftBadge(
                      label: 'Revisar primeiro',
                      icon: Icons.bolt_outlined,
                      color: AppColors.accentGold,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (compact) ...[
                main,
                const SizedBox(height: 14),
                actionPanel,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    const SizedBox(width: 18),
                    SizedBox(width: 258, child: actionPanel),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RequisitionCardMain extends StatelessWidget {
  final MaterialRequisitionModel requisition;
  final DateFormat dateFormat;

  const _RequisitionCardMain({
    required this.requisition,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = requisition.items.take(4).toList();
    final remaining = requisition.items.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requisition.projectName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          requisition.itemsSummary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            _MiniInfo(
              icon: Icons.person_outline,
              label: requisition.requesterName,
            ),
            _MiniInfo(
              icon: Icons.apartment_outlined,
              label: requisition.requesterSector,
            ),
            _MiniInfo(
              icon: Icons.event_outlined,
              label: dateFormat.format(requisition.requestDate),
            ),
            _MiniInfo(
              icon: Icons.inventory_2_outlined,
              label:
                  '${requisition.itemCount} itens / ${_formatQuantity(requisition.totalQuantity)} un.',
            ),
          ],
        ),
        if (visibleItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visibleItems.map((item) => _ItemChip(item: item)),
              if (remaining > 0)
                _SoftBadge(
                  label: '+$remaining itens',
                  icon: Icons.more_horiz,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ],
        if (requisition.rejectionReason?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _NoticeLine(
            icon: Icons.cancel_outlined,
            label: requisition.rejectionReason!.trim(),
            color: AppColors.accentRed,
          ),
        ],
        if (requisition.approvedByName?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _NoticeLine(
            icon: Icons.verified_user_outlined,
            label:
                'Aprovado por ${requisition.approvedByName!.trim()}'
                '${requisition.approvedAt == null ? '' : ' em ${dateFormat.format(requisition.approvedAt!)}'}',
            color: AppColors.accentGreen,
          ),
        ],
        if (requisition.purchaseId?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _NoticeLine(
            icon: Icons.shopping_cart_checkout_outlined,
            label: 'Compra vinculada: ${requisition.purchaseId!.trim()}',
            color: AppColors.accentBlue,
          ),
        ],
      ],
    );
  }
}

class _RequisitionActionPanel extends StatelessWidget {
  final MaterialRequisitionModel requisition;
  final VoidCallback onOpenQuotes;

  const _RequisitionActionPanel({
    required this.requisition,
    required this.onOpenQuotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardInnerSurface(
        accent: requisition.status.color,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: requisition.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  requisition.status.icon,
                  color: requisition.status.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requisition.status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _relativeDate(requisition.requestDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CompactMetric(
            label: 'Itens',
            value: requisition.itemCount.toString(),
            icon: Icons.format_list_bulleted,
          ),
          const SizedBox(height: 8),
          _CompactMetric(
            label: 'Quantidade',
            value: _formatQuantity(requisition.totalQuantity),
            icon: Icons.straighten_outlined,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOpenQuotes,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.request_quote_outlined, size: 17),
            label: const Text(
              'Orcar fornecedores',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFilterRow extends StatelessWidget {
  final bool showStats;
  final _RequisitionSummary summary;
  final TextEditingController controller;
  final String query;
  final _RequisitionSort sort;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_RequisitionSort?> onSortChanged;

  const _SummaryFilterRow({
    required this.showStats,
    required this.summary,
    required this.controller,
    required this.query,
    required this.sort,
    required this.visibleCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final toolbar = _Toolbar(
      controller: controller,
      query: query,
      sort: sort,
      visibleCount: visibleCount,
      totalCount: totalCount,
      onQueryChanged: onQueryChanged,
      onClear: onClear,
      onSortChanged: onSortChanged,
    );

    if (!showStats) return toolbar;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatsRow(summary: summary)),
              const SizedBox(width: 12),
              SizedBox(width: 520, child: toolbar),
            ],
          );
        }

        return Column(
          children: [
            _StatsRow(summary: summary),
            const SizedBox(height: 10),
            toolbar,
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _RequisitionSort sort;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_RequisitionSort?> onSortChanged;

  const _Toolbar({
    required this.controller,
    required this.query,
    required this.sort,
    required this.visibleCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final search = TextField(
          controller: controller,
          onChanged: onQueryChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primaryDark.withValues(alpha: 0.36),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textMuted,
              size: 19,
            ),
            suffixIcon:
                query.isEmpty
                    ? null
                    : IconButton(
                      onPressed: onClear,
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close, size: 18),
                    ),
            hintText: 'Buscar por obra, solicitante, setor ou item',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
          ),
        );
        final controls = LayoutBuilder(
          builder: (context, controlConstraints) {
            final stacked = controlConstraints.maxWidth < 330;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SortDropdown(value: sort, onChanged: onSortChanged),
                  const SizedBox(height: 8),
                  _ResultCounter(
                    visibleCount: visibleCount,
                    totalCount: totalCount,
                    expand: true,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _SortDropdown(value: sort, onChanged: onSortChanged),
                ),
                const SizedBox(width: 10),
                _ResultCounter(
                  visibleCount: visibleCount,
                  totalCount: totalCount,
                ),
              ],
            );
          },
        );

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: AppDecorations.cardInnerSurface(radius: 14),
          child:
              compact
                  ? Column(
                    children: [search, const SizedBox(height: 10), controls],
                  )
                  : Row(
                    children: [
                      Expanded(flex: 3, child: search),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: controls),
                    ],
                  ),
        );
      },
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _RequisitionSort value;
  final ValueChanged<_RequisitionSort?> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_RequisitionSort>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.secondaryDark,
          iconEnabledColor: AppColors.accentGold,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          selectedItemBuilder:
              (context) =>
                  _RequisitionSort.values
                      .map(
                        (sort) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            sort.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
          items:
              _RequisitionSort.values
                  .map(
                    (sort) => DropdownMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(sort.icon, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sort.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResultCounter extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final bool expand;

  const _ResultCounter({
    required this.visibleCount,
    required this.totalCount,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: expand ? double.infinity : null,
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exibindo',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$visibleCount de $totalCount',
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _RequisitionSummary summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        label: 'Pendentes',
        value: summary.pending.toString(),
        icon: Icons.hourglass_empty_rounded,
        color: AppColors.accentGold,
        caption: 'Aguardando aprovacao',
      ),
      _StatTile(
        label: 'Alta prioridade',
        value: summary.highPriority.toString(),
        icon: Icons.priority_high_outlined,
        color: AppColors.accentRed,
        caption: 'Pendencias criticas',
      ),
      _StatTile(
        label: 'Em compras',
        value: summary.purchased.toString(),
        icon: Icons.shopping_cart_outlined,
        color: AppColors.accentBlue,
        caption: 'Ja viraram compra',
      ),
      _StatTile(
        label: 'Entregues',
        value: summary.delivered.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppColors.accentGreen,
        caption: '${summary.total} no total',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder:
                  (context, index) => SizedBox(width: 190, child: tiles[index]),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i]),
              if (i != tiles.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String caption;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.statCardSurface(color, radius: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return _SoftBadge(
      label: 'Prioridade $priority',
      icon: Icons.flag_outlined,
      color: color,
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SoftBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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

class _ItemChip extends StatelessWidget {
  final RequisitionItem item;

  const _ItemChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${_formatQuantity(item.quantity)} ${item.unit} - ${item.itemName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoticeLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NoticeLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 360,
              padding: EdgeInsets.all(compact ? 14 : 24),
              decoration: AppDecorations.cardInnerSurface(
                accent: AppColors.textMuted,
                radius: 16,
              ),
              child:
                  compact
                      ? Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.assignment_late_outlined,
                              color: AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ajuste a busca ou acompanhe novas solicitacoes quando chegarem.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }
}

class _RequisitionSummary {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int purchased;
  final int delivered;
  final int highPriority;
  final DateTime? oldestPending;

  const _RequisitionSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.purchased,
    required this.delivered,
    required this.highPriority,
    required this.oldestPending,
  });

  factory _RequisitionSummary.from(
    List<MaterialRequisitionModel> requisitions,
  ) {
    final pendingItems =
        requisitions
            .where((item) => item.status == RequisitionStatus.pending)
            .toList()
          ..sort((a, b) => a.requestDate.compareTo(b.requestDate));

    return _RequisitionSummary(
      total: requisitions.length,
      pending:
          requisitions
              .where((item) => item.status == RequisitionStatus.pending)
              .length,
      approved:
          requisitions
              .where((item) => item.status == RequisitionStatus.approved)
              .length,
      rejected:
          requisitions
              .where((item) => item.status == RequisitionStatus.rejected)
              .length,
      purchased:
          requisitions
              .where((item) => item.status == RequisitionStatus.purchased)
              .length,
      delivered:
          requisitions
              .where((item) => item.status == RequisitionStatus.delivered)
              .length,
      highPriority:
          requisitions
              .where(
                (item) =>
                    item.status == RequisitionStatus.pending &&
                    _priorityRank(item.priority) >= 3,
              )
              .length,
      oldestPending:
          pendingItems.isEmpty ? null : pendingItems.first.requestDate,
    );
  }
}

String _formatQuantity(double quantity) {
  return quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
}

int _priorityRank(String priority) {
  final normalized = priority.toLowerCase();
  if (normalized.contains('alta') || normalized.contains('high')) return 3;
  if (normalized.contains('baixa') || normalized.contains('low')) return 1;
  return 2;
}

int _statusRank(RequisitionStatus status) {
  return switch (status) {
    RequisitionStatus.pending => 5,
    RequisitionStatus.approved => 4,
    RequisitionStatus.purchased => 3,
    RequisitionStatus.delivered => 2,
    RequisitionStatus.rejected => 1,
  };
}

Color _priorityColor(String priority) {
  return switch (_priorityRank(priority)) {
    3 => AppColors.accentRed,
    1 => AppColors.accentBlue,
    _ => AppColors.accentGold,
  };
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays <= 0) return 'Solicitada hoje';
  if (difference.inDays == 1) return 'Solicitada ontem';
  if (difference.inDays < 30) return 'Ha ${difference.inDays} dias';
  return DateFormat('dd/MM/yyyy').format(date);
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
    final statusAccent = switch (quote.status) {
      RequisitionQuoteStatus.selected => AppColors.accentGold,
      RequisitionQuoteStatus.rejected => AppColors.accentRed,
      RequisitionQuoteStatus.sent => AppColors.accentBlue,
      RequisitionQuoteStatus.draft => AppColors.textMuted,
      RequisitionQuoteStatus.received => AppColors.accentGreen,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardSurface(
        accent: quote.isSelected ? AppColors.accentGold : statusAccent,
        emphasized: quote.isSelected,
        radius: 14,
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
  return granithInputDecoration(
    label: label,
    hint: '',
    icon: icon,
    accentColor: AppColors.accentGold,
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
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
