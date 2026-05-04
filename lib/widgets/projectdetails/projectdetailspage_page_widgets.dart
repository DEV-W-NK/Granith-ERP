import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

// Temas e Modelos
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/models/purchase_model.dart';

// Widgets Partilhados
import 'package:project_granith/widgets/projects/ProjectBudgetSummary.dart';
import 'package:project_granith/widgets/projects/project_image.dart';
import 'package:project_granith/helpers/projects_helpers.dart';
import 'package:project_granith/ViewModels/ProjectDetailsViewModel.dart';

class ProjectDetailsPageView extends StatefulWidget {
  const ProjectDetailsPageView({super.key});

  @override
  State<ProjectDetailsPageView> createState() => _ProjectDetailsPageViewState();
}

class _ProjectDetailsPageViewState extends State<ProjectDetailsPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjectDetailsViewModel>();
    final p = viewModel.project;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar(context, p, isDesktop)],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ResumoTab(project: p),
                  _FinanceiroTab(project: p),
                  _DiarioTab(project: p),
                  _EquipeTab(project: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Project p, bool isDesktop) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ProjectImageWidget(imageUrl: p.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black38,
                    AppColors.primaryDark.withOpacity(0.95),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPill(project: p),
                      if (p.isOverBudget) ...[
                        const SizedBox(width: 8),
                        _AlertPill(
                          label: 'Orçamento estourado',
                          color: AppColors.accentRed,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.location,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: AppColors.accentGold),
          onPressed: () => showProjectDialog(context, project: p),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primaryDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentGold,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Resumo'),
          Tab(
            icon: Icon(Icons.account_balance_outlined, size: 18),
            text: 'Financeiro',
          ),
          Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Diário'),
          Tab(icon: Icon(Icons.groups_outlined, size: 18), text: 'Equipe'),
        ],
      ),
    );
  }
}

// ─── ABA RESUMO ─────────────────────────────────────────────────────────────

class _ResumoTab extends StatelessWidget {
  final Project project;
  const _ResumoTab({required this.project});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProjectBudgetSummary(
          project: project,
          compact: false,
          showBreakdown: true,
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Informações Gerais',
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.description_outlined,
                label: 'Descrição',
                value:
                    project.description.isEmpty
                        ? 'Sem descrição'
                        : project.description,
              ),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Cliente',
                value: project.client,
              ),
              _InfoRow(
                icon: Icons.attach_money,
                label: 'Budget Previsto',
                value: currency.format(project.budget),
              ),
              _InfoRow(
                icon: Icons.calendar_today,
                label: 'Início',
                value: DateFormat('dd/MM/yyyy').format(project.startDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Últimas Compras',
          child: _RecentPurchasesPreview(projectId: project.id),
        ),
      ],
    );
  }
}

// ─── ABA FINANCEIRO ─────────────────────────────────────────────────────────

class _FinanceiroTab extends StatelessWidget {
  final Project project;
  const _FinanceiroTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinancialTransactionModel>>(
      stream: AppSupabase.client
          .from('financial_transactions')
          .stream(primaryKey: ['id'])
          .eq('projectId', project.id)
          .order('dueDate', ascending: false)
          .map(
            (rows) =>
                rows.map((row) {
                  final data = Map<String, dynamic>.from(row);
                  return FinancialTransactionModel.fromMap(
                    data,
                    data['id'] as String? ?? '',
                  );
                }).toList(),
          ),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        final transactions = snap.data!;
        if (transactions.isEmpty)
          return const _EmptyState(
            icon: Icons.account_balance_wallet,
            label: 'Nenhuma transação registrada',
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, i) {
            final t = transactions[i];
            final isIncome = t.type == TransactionType.income;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color:
                        isIncome ? AppColors.accentGreen : AppColors.accentRed,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yy').format(t.dueDate),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? "+" : "-"} R\$ ${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isIncome ? AppColors.accentGreen : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

// ─── ABA DIÁRIO DE OBRA ─────────────────────────────────────────────────────

class _DiarioTab extends StatelessWidget {
  final Project project;
  const _DiarioTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DailyLogModel>>(
      stream: AppSupabase.client
          .from('daily_logs')
          .stream(primaryKey: ['id'])
          .eq('projectId', project.id)
          .order('date', ascending: false)
          .map(
            (rows) =>
                rows.map((row) {
                  final data = Map<String, dynamic>.from(row);
                  return DailyLogModel.fromMap(
                    data,
                    data['id'] as String? ?? '',
                  );
                }).toList(),
          ),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        final logs = snap.data!;
        if (logs.isEmpty)
          return const _EmptyState(
            icon: Icons.menu_book,
            label: 'Nenhum registro no diário',
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, i) {
            final log = logs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'dd/MM/yyyy — EEEE',
                          'pt_BR',
                        ).format(log.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.activitiesDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ─── ABA EQUIPE ─────────────────────────────────────────────────────────────

class _EquipeTab extends StatelessWidget {
  final Project project;
  const _EquipeTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: AppSupabase.client
          .from('teams')
          .stream(primaryKey: ['id'])
          .map(
            (rows) =>
                rows.map((row) {
                  final data = Map<String, dynamic>.from(row);
                  return TeamModel.fromMap(data, data['id'] as String? ?? '');
                }).toList(),
          )
          .map(
            (teams) =>
                teams
                    .where(
                      (team) => team.projectId == project.id && team.isActive,
                    )
                    .toList(),
          ),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );
        final teams = snap.data!;
        if (teams.isEmpty)
          return const _EmptyState(
            icon: Icons.groups,
            label: 'Nenhuma equipe vinculada',
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, i) {
            final team = teams[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team.memberIds.length} membros ativos',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
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

// ─── COMPONENTES AUXILIARES ─────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Project project;
  const _StatusPill({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: project.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: project.status.color.withOpacity(0.4)),
      ),
      child: Text(
        project.status.displayName,
        style: TextStyle(
          color: project.status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AlertPill extends StatelessWidget {
  final String label;
  final Color color;
  const _AlertPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RecentPurchasesPreview extends StatelessWidget {
  final String projectId;
  const _RecentPurchasesPreview({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Purchase>>(
      stream: AppSupabase.client
          .from('purchases')
          .stream(primaryKey: ['id'])
          .eq('projectId', projectId)
          .limit(3)
          .map(
            (rows) =>
                rows.map((row) {
                  final data = Map<String, dynamic>.from(row);
                  return Purchase.fromMap(data, data['id'] as String? ?? '');
                }).toList(),
          ),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final purchases = snap.data!;
        if (purchases.isEmpty)
          return const Text(
            'Nenhuma compra registrada',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          );
        return Column(
          children:
              purchases
                  .map(
                    (p) => ListTile(
                      dense: true,
                      title: Text(
                        p.itemName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        'R\$ ${p.totalValue}',
                        style: const TextStyle(color: AppColors.accentGold),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
