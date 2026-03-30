import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/helpers/projects_helpers.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/ProjectBudgetSummary.dart';
import 'package:project_granith/widgets/projects/project_image.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage>
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
    final p = widget.project;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(p, isDesktop),
        ],
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

  // ─── App bar com imagem ───────────────────────────────────────────────────

  SliverAppBar _buildAppBar(Project p, bool isDesktop) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: AppColors.accentGold),
          tooltip: 'Editar projeto',
          onPressed: () => showProjectDialog(context, project: p),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem de fundo
            ProjectImageWidget(
              imageUrl: p.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Gradiente para legibilidade
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    AppColors.primaryDark.withOpacity(0.95),
                  ],
                ),
              ),
            ),
            // Conteúdo do header
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
                      const SizedBox(width: 8),
                      if (p.isOverBudget)
                        _AlertPill(
                            label: 'Orçamento estourado',
                            color: Colors.redAccent),
                      if (p.isOverdue)
                        _AlertPill(
                            label: 'Prazo vencido',
                            color: Colors.orangeAccent),
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
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 4),
                      Text(p.client,
                          style: const TextStyle(
                              color: AppColors.accentGold, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.location,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(p.startDate)} → ${p.endDate != null ? dateFormat.format(p.endDate!) : "Em aberto"}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                      if (p.daysUntilDeadline != null &&
                          !p.isCompleted) ...[
                        const SizedBox(width: 12),
                        Text(
                          p.isOverdue
                              ? 'Vencido'
                              : '${p.daysUntilDeadline} dias restantes',
                          style: TextStyle(
                            color: p.isOverdue
                                ? Colors.orangeAccent
                                : AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primaryDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentGold,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        isScrollable: false,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Resumo'),
          Tab(
              icon: Icon(Icons.account_balance_outlined, size: 18),
              text: 'Financeiro'),
          Tab(
              icon: Icon(Icons.menu_book_outlined, size: 18),
              text: 'Diário'),
          Tab(icon: Icon(Icons.groups_outlined, size: 18), text: 'Equipe'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 1 — RESUMO
// ═══════════════════════════════════════════════════════════════════════════

class _ResumoTab extends StatelessWidget {
  final Project project;
  const _ResumoTab({required this.project});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Budget vs Realizado completo
        ProjectBudgetSummary(
          project: project,
          compact: false,
          showBreakdown: true,
        ),
        const SizedBox(height: 16),

        // Informações do projeto
        _Section(
          title: 'Informações',
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.description_outlined,
                  label: 'Descrição',
                  value: project.description.isEmpty
                      ? 'Sem descrição'
                      : project.description),
              _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Orçamento previsto',
                  value: currency.format(project.budget)),
              _InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Equipe',
                  value: '${project.teamSize} pessoa(s)'),
              if (project.tags.isNotEmpty)
                _InfoRow(
                  icon: Icons.label_outline,
                  label: 'Tags',
                  value: project.tags.join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Últimas compras (preview)
        _Section(
          title: 'Últimas compras',
          action: TextButton(
            onPressed: () {},
            child: const Text('Ver todas',
                style: TextStyle(
                    color: AppColors.accentGold, fontSize: 12)),
          ),
          child: _RecentPurchasesPreview(projectId: project.id),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 2 — FINANCEIRO
// ═══════════════════════════════════════════════════════════════════════════

class _FinanceiroTab extends StatelessWidget {
  final Project project;
  const _FinanceiroTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinancialTransactionModel>>(
      stream: FirebaseFirestore.instance
          .collection('financial_transactions')
          .where('projectId', isEqualTo: project.id)
          .orderBy('dueDate', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => FinancialTransactionModel.fromMap(
                  d.data(), d.id))
              .toList()),
      builder: (context, snap) {
        final transactions = snap.data ?? [];
        final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
        final dateFormat = DateFormat('dd/MM/yy');

        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold));
        }

        if (transactions.isEmpty) {
          return _EmptyState(
            icon: Icons.account_balance_outlined,
            label: 'Nenhuma transação neste projeto',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (_, i) {
            final t = transactions[i];
            final isIncome = t.type == TransactionType.income;
            final statusColor = _statusColor(t.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isIncome
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.description,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _MiniChip(_categoryLabel(t.category)),
                            const SizedBox(width: 6),
                            Text(dateFormat.format(t.dueDate),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? "+" : "−"} ${currency.format(t.amount)}',
                        style: TextStyle(
                          color: isIncome
                              ? Colors.greenAccent
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _statusLabel(t.status),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(TransactionStatus s) => switch (s) {
        TransactionStatus.paid => Colors.green,
        TransactionStatus.overdue => Colors.redAccent,
        TransactionStatus.cancelled => Colors.grey,
        TransactionStatus.pending => Colors.orange,
      };

  String _statusLabel(TransactionStatus s) => switch (s) {
        TransactionStatus.paid => 'PAGO',
        TransactionStatus.overdue => 'VENCIDO',
        TransactionStatus.cancelled => 'CANCELADO',
        TransactionStatus.pending => 'PENDENTE',
      };

  String _categoryLabel(TransactionCategory c) => switch (c) {
        TransactionCategory.material => 'Material',
        TransactionCategory.labor => 'M. de obra',
        TransactionCategory.equipment => 'Equipamento',
        TransactionCategory.administrative => 'Adm.',
        TransactionCategory.measurement => 'Medição',
        TransactionCategory.tax => 'Imposto',
        TransactionCategory.other => 'Outro',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 3 — DIÁRIO DE OBRA
// ═══════════════════════════════════════════════════════════════════════════

class _DiarioTab extends StatelessWidget {
  final Project project;
  const _DiarioTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DailyLogModel>>(
      stream: FirebaseFirestore.instance
          .collection('daily_logs')
          .where('projectId', isEqualTo: project.id)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) =>
                  DailyLogModel.fromMap(d.data(), d.id))
              .toList()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold));
        }

        final logs = snap.data!;

        if (logs.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_outlined,
            label: 'Nenhum registro no diário de obra',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (_, i) => _DiarioCard(log: logs[i]),
        );
      },
    );
  }
}

class _DiarioCard extends StatelessWidget {
  final DailyLogModel log;
  const _DiarioCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy — EEEE', 'pt_BR');
    final totalWorkers =
        log.manpower.values.fold(0, (sum, v) => sum + v);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.impediments.isNotEmpty
              ? Colors.orangeAccent.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: data + clima + status
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(log.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              _WeatherIcon(log.weatherMorning),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward,
                  size: 10, color: AppColors.textMuted),
              const SizedBox(width: 4),
              _WeatherIcon(log.weatherAfternoon),
              const SizedBox(width: 8),
              _LogStatusBadge(log.status),
            ],
          ),
          const SizedBox(height: 10),

          // Atividades
          Text(
            log.activitiesDescription,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Impedimentos
          if (log.impediments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: Colors.orangeAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log.impediments,
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Mão de obra + fotos
          Row(
            children: [
              const Icon(Icons.engineering_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '$totalWorkers trabalhador(es)',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
              if (log.manpower.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.manpower.entries
                        .map((e) => '${e.value}× ${e.key}')
                        .join(', '),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (log.photoUrls.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.photo_library_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text('${log.photoUrls.length}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  final WeatherCondition condition;
  const _WeatherIcon(this.condition);

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (condition) {
      WeatherCondition.sol => (Icons.wb_sunny_outlined, Colors.amber),
      WeatherCondition.nublado =>
        (Icons.cloud_outlined, AppColors.textMuted),
      WeatherCondition.chuvoso =>
        (Icons.umbrella_outlined, Colors.blueAccent),
      WeatherCondition.tempestade =>
        (Icons.thunderstorm_outlined, Colors.purpleAccent),
    };
    return Icon(icon, size: 16, color: color);
  }
}

class _LogStatusBadge extends StatelessWidget {
  final LogStatus status;
  const _LogStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LogStatus.draft => ('Rascunho', Colors.orange),
      LogStatus.finalized => ('Finalizado', Colors.green),
      LogStatus.synced => ('Sincronizado', Colors.blueAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 4 — EQUIPE
// ═══════════════════════════════════════════════════════════════════════════

class _EquipeTab extends StatelessWidget {
  final Project project;
  const _EquipeTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('projectId', isEqualTo: project.id)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => TeamModel.fromMap(d.data(), d.id))
              .toList()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold));
        }

        final teams = snap.data!;

        if (teams.isEmpty) {
          return _EmptyState(
            icon: Icons.groups_outlined,
            label: 'Nenhuma equipe vinculada a este projeto',
            sublabel:
                'Vincule uma equipe no cadastro de equipes',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (_, i) => _TeamCard(team: teams[i]),
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome + contagem
          Row(
            children: [
              const Icon(Icons.groups_outlined,
                  size: 16, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              _MiniChip('${team.memberIds.length} membros'),
            ],
          ),

          if (team.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(team.description,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],

          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),

          // Membros
          _MembersList(
              memberIds: team.memberIds,
              leaderId: team.leaderId),
        ],
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  final List<String> memberIds;
  final String? leaderId;

  const _MembersList(
      {required this.memberIds, required this.leaderId});

  @override
  Widget build(BuildContext context) {
    if (memberIds.isEmpty) {
      return const Text('Sem membros cadastrados',
          style:
              TextStyle(color: AppColors.textMuted, fontSize: 12));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('employees')
          .where(FieldPath.documentId, whereIn: memberIds)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 24,
              child: Center(
                  child: LinearProgressIndicator(
                      color: AppColors.accentGold)));
        }

        final employees = snap.data!.docs
            .map((d) => EmployeeModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList();

        return Column(
          children: employees
              .map((e) => _EmployeeRow(
                  employee: e,
                  isLeader: e.id == leaderId))
              .toList(),
        );
      },
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final EmployeeModel employee;
  final bool isLeader;

  const _EmployeeRow(
      {required this.employee, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (employee.role) {
      EmployeeRole.coordenador => Colors.purpleAccent,
      EmployeeRole.supervisor => AppColors.accentGold,
      EmployeeRole.funcionario => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor.withOpacity(0.15),
            backgroundImage: employee.photoUrl.isNotEmpty
                ? NetworkImage(employee.photoUrl)
                : null,
            child: employee.photoUrl.isEmpty
                ? Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Nome + cargo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppColors.accentGold),
                    ],
                  ],
                ),
                Text(
                  employee.jobTitle,
                  style: TextStyle(
                      color: roleColor.withOpacity(0.8),
                      fontSize: 11),
                ),
              ],
            ),
          ),

          // Status
          _StatusDot(employee.status),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final EmployeeStatus status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, label) =  switch(status) {
            EmployeeStatus.ativo      => (Colors.greenAccent, 'Ativo'),
           EmployeeStatus.ferias     => (Colors.blueAccent, 'Férias'),
            EmployeeStatus.afastado   => (Colors.orangeAccent, 'Afastado'),  // <-- ADICIONAR
            EmployeeStatus.desligado  => (Colors.redAccent, 'Desligado'),
        };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 3, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMO — subwidgets
// ═══════════════════════════════════════════════════════════════════════════

class _RecentPurchasesPreview extends StatelessWidget {
  final String projectId;
  const _RecentPurchasesPreview({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yy');

    return StreamBuilder<List<Purchase>>(
      stream: FirebaseFirestore.instance
          .collection('purchases')
          .where('projectId', isEqualTo: projectId)
          .orderBy('purchaseDate', descending: true)
          .limit(4)
          .snapshots()
          .map((s) => s.docs
              .map((d) =>
                  Purchase.fromMap(d.data(), d.id))
              .toList()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 40,
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                      strokeWidth: 2)));
        }

        final purchases = snap.data!;

        if (purchases.isEmpty) {
          return const Text('Nenhuma compra registrada',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12));
        }

        return Column(
          children: purchases
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: p.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.shopping_cart_outlined,
                              size: 14, color: p.status.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(p.itemName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(p.supplierName,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(p.totalValue),
                                style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            Text(dateFormat.format(p.purchaseDate),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTILHADOS
// ═══════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Section(
      {required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              if (action != null) action!,
            ],
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

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;

  const _EmptyState(
      {required this.icon, required this.label, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 52,
              color: AppColors.textMuted.withOpacity(0.2)),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14)),
          if (sublabel != null) ...[
            const SizedBox(height: 6),
            Text(sublabel!,
                style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: 12)),
          ],
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: project.status.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: project.status.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
              radius: 3,
              backgroundColor: project.status.color),
          const SizedBox(width: 5),
          Text(project.status.displayName,
              style: TextStyle(
                  color: project.status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}