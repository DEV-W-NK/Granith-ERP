import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/BenefitModel.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';
import 'package:project_granith/models/SalaryHistoryModel.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/services/HrService.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF0F1117);
  static const s1      = Color(0xFF161B27);
  static const s2      = Color(0xFF1C2333);
  static const s3      = Color(0xFF222A3D);
  static const border  = Color(0x12FFFFFF);
  static const border2 = Color(0x1FFFFFFF);
  static const gold    = Color(0xFFC9A84C);
  static const gold2   = Color(0xFFE8C56A);
  static const goldDim = Color(0x22C9A84C);
  static const goldBdr = Color(0x4DC9A84C);
  static const tx      = Color(0xFFE8EAF0);
  static const tx2     = Color(0xFF8B93A8);
  static const tx3     = Color(0xFF5A6178);
  static const green   = Color(0xFF3ECF8E);
  static const greenDim= Color(0x1A3ECF8E);
  static const red     = Color(0xFFF87171);
  static const redDim  = Color(0x1AF87171);
  static const blue    = Color(0xFF60A5FA);
  static const blueDim = Color(0x1A60A5FA);
  static const orange  = Color(0xFFFB923C);
}

final _brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
final _date = DateFormat('dd/MM/yyyy');

// ─────────────────────────────────────────────────────────────────────────────
// HR PAGE
// ─────────────────────────────────────────────────────────────────────────────
class HrPage extends StatefulWidget {
  const HrPage({super.key});

  @override
  State<HrPage> createState() => _HrPageState();
}

class _HrPageState extends State<HrPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _hrService = HrService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    context.read<TeamController>().init();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _EmployeesTab(hrService: _hrService),
                  _BenefitsTab(hrService: _hrService),
                  _JobRolesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<List<EmployeeModel>>(
      stream: _hrService.watchEmployees(),
      builder: (context, snap) {
        final employees = snap.data ?? [];
        final ativos    = employees.where((e) => e.isActive).length;
        final ferias    = employees.where((e) => e.isOnLeave).length;
        final deslig    = employees.where((e) => e.isDismissed).length;

        return Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _C.goldDim,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _C.goldBdr),
              ),
              child: const Icon(Icons.people_alt_rounded, color: _C.gold, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestão de RH',
                      style: TextStyle(color: _C.tx, fontSize: 17,
                          fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                  SizedBox(height: 2),
                  Text('Colaboradores, benefícios e cargos',
                      style: TextStyle(color: _C.tx3, fontSize: 12)),
                ],
              ),
            ),
            _StatPill(label: 'Ativos',    count: ativos, color: _C.green),
            const SizedBox(width: 8),
            _StatPill(label: 'Férias',    count: ferias, color: _C.blue),
            const SizedBox(width: 8),
            _StatPill(label: 'Desligados',count: deslig, color: _C.red),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: _C.goldDim,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _C.goldBdr),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _C.gold2,
        unselectedLabelColor: _C.tx3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.people_rounded, size: 16),      text: 'Colaboradores'),
          Tab(icon: Icon(Icons.card_giftcard_rounded, size: 16),text: 'Benefícios'),
          Tab(icon: Icon(Icons.work_rounded, size: 16),         text: 'Cargos'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ABA 1 — COLABORADORES
// ═════════════════════════════════════════════════════════════════════════════
class _EmployeesTab extends StatefulWidget {
  final HrService hrService;
  const _EmployeesTab({required this.hrService});

  @override
  State<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<_EmployeesTab> {
  String _search = '';
  EmployeeStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros
        Row(
          children: [
            Expanded(
              child: _SearchField(
                hint: 'Buscar por nome, cargo ou setor...',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 12),
            _TabFilter(label: 'Todos',      selected: _filterStatus == null,                         onTap: () => setState(() => _filterStatus = null)),
            const SizedBox(width: 6),
            _TabFilter(label: 'Ativos',     selected: _filterStatus == EmployeeStatus.ativo,          onTap: () => setState(() => _filterStatus = EmployeeStatus.ativo)),
            const SizedBox(width: 6),
            _TabFilter(label: 'Férias',     selected: _filterStatus == EmployeeStatus.ferias,         onTap: () => setState(() => _filterStatus = EmployeeStatus.ferias)),
            const SizedBox(width: 6),
            _TabFilter(label: 'Desligados', selected: _filterStatus == EmployeeStatus.desligado,      onTap: () => setState(() => _filterStatus = EmployeeStatus.desligado)),
            const SizedBox(width: 12),
            _AddBtn(
              label: 'Novo colaborador',
              onTap: () => _showEmployeeForm(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Lista
        Expanded(
          child: StreamBuilder<List<EmployeeModel>>(
            stream: widget.hrService.watchEmployees(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _C.gold, strokeWidth: 2));
              }
              final all = snap.data ?? [];
              final filtered = all.where((e) {
                final q = _search.toLowerCase();
                final matchS = q.isEmpty ||
                    e.name.toLowerCase().contains(q) ||
                    e.jobTitle.toLowerCase().contains(q) ||
                    e.sector.toLowerCase().contains(q);
                final matchF = _filterStatus == null || e.status == _filterStatus;
                return matchS && matchF;
              }).toList();

              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.people_outline_rounded,
                  message: _search.isNotEmpty
                      ? 'Nenhum colaborador encontrado.'
                      : 'Nenhum colaborador cadastrado.',
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _EmployeeCard(
                  employee: filtered[i],
                  hrService: widget.hrService,
                  onDismiss: () => _confirmDismissal(context, filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEmployeeForm(BuildContext context, [EmployeeModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.s1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmployeeFormSheet(
        hrService: widget.hrService,
        existing: existing,
      ),
    );
  }

  void _confirmDismissal(BuildContext context, EmployeeModel employee) {
    if (employee.isDismissed) return;
    showDialog(
      context: context,
      builder: (_) => _DismissDialog(
        employee:  employee,
        hrService: widget.hrService,
      ),
    );
  }
}

// ─── Employee Card ────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final HrService hrService;
  final VoidCallback onDismiss;

  const _EmployeeCard({
    required this.employee,
    required this.hrService,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = employee.isDismissed
        ? _C.red
        : employee.isOnLeave
            ? _C.blue
            : _C.green;

    return Container(
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: employee.isDismissed
              ? _C.red.withValues(alpha: 0.15)
              : _C.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Text(employee.initials,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          title: Text(employee.name,
              style: TextStyle(
                color: employee.isDismissed ? _C.tx3 : _C.tx,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: employee.isDismissed ? TextDecoration.lineThrough : null,
                decorationColor: _C.tx3,
              )),
          subtitle: Text('${employee.jobTitle} · ${employee.sector}',
              style: const TextStyle(color: _C.tx3, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusBadge(status: employee.status),
              const SizedBox(width: 8),
              Text(_brl.format(employee.baseSalary),
                  style: const TextStyle(color: _C.tx2, fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: _C.tx3, size: 18),
            ],
          ),
          children: [
            _EmployeeDetails(
              employee:  employee,
              hrService: hrService,
              onDismiss: onDismiss,
              onEdit: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: _C.s1,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => _EmployeeFormSheet(
                    hrService: hrService,
                    existing: employee,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Employee Details (dentro do ExpansionTile) ───────────────────────────────
class _EmployeeDetails extends StatelessWidget {
  final EmployeeModel employee;
  final HrService hrService;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;

  const _EmployeeDetails({
    required this.employee,
    required this.hrService,
    required this.onDismiss,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _C.border, height: 16),

        // Info grid
        Wrap(
          spacing: 24, runSpacing: 8,
          children: [
            _InfoItem(label: 'CPF',        value: employee.cpf.isEmpty      ? '—' : employee.cpf),
            _InfoItem(label: 'CTPS',       value: employee.ctps.isEmpty     ? '—' : employee.ctps),
            _InfoItem(label: 'Admissão',   value: _date.format(employee.admissionDate)),
            if (employee.dismissalDate != null)
              _InfoItem(label: 'Desligamento', value: _date.format(employee.dismissalDate!)),
            _InfoItem(label: 'E-mail',     value: employee.email.isEmpty    ? '—' : employee.email),
            _InfoItem(label: 'Telefone',   value: employee.phone.isEmpty    ? '—' : employee.phone),
            _InfoItem(label: 'Escolaridade', value: employee.educationLevel.isEmpty ? '—' : employee.educationLevel),
            if (employee.courses.isNotEmpty)
              _InfoItem(label: 'Cursos', value: employee.courses),
          ],
        ),

        const SizedBox(height: 14),

        // Benefícios ativos
        StreamBuilder<List<EmployeeBenefitModel>>(
          stream: hrService.watchEmployeeBenefits(employee.id),
          builder: (_, snap) {
            final benefits = snap.data ?? [];
            if (benefits.isEmpty) return const SizedBox.shrink();
            final total = benefits.fold(0.0, (s, b) => s + b.monthlyValue);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Benefícios ativos',
                      style: TextStyle(color: _C.tx2, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const Spacer(),
                  Text('Total: ${_brl.format(total)}/mês',
                      style: const TextStyle(color: _C.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: benefits.map((b) => _BenefitChip(benefit: b)).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),

        // Histórico salarial (últimos 3)
        StreamBuilder<List<SalaryHistoryModel>>(
          stream: hrService.watchSalaryHistory(employee.id),
          builder: (_, snap) {
            final history = (snap.data ?? []).take(3).toList();
            if (history.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico salarial',
                    style: TextStyle(color: _C.tx2, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                ...history.map((h) => _SalaryHistoryTile(history: h)),
                const SizedBox(height: 8),
              ],
            );
          },
        ),

        // Ações
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!employee.isDismissed) ...[
              _ActionBtn(
                label: 'Reajuste',
                icon: Icons.trending_up_rounded,
                color: _C.green,
                onTap: () => _showRaiseDialog(context),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Benefício',
                icon: Icons.add_card_rounded,
                color: _C.blue,
                onTap: () => _showAssignBenefitSheet(context),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Editar',
                icon: Icons.edit_rounded,
                color: _C.gold,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Desligar',
                icon: Icons.exit_to_app_rounded,
                color: _C.red,
                onTap: onDismiss,
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showRaiseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _RaiseDialog(employee: employee, hrService: hrService),
    );
  }

  void _showAssignBenefitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.s1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AssignBenefitSheet(
        employee:  employee,
        hrService: hrService,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ABA 2 — BENEFÍCIOS
// ═════════════════════════════════════════════════════════════════════════════
class _BenefitsTab extends StatelessWidget {
  final HrService hrService;
  const _BenefitsTab({required this.hrService});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _AddBtn(
              label: 'Novo benefício',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: _C.s1,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _BenefitFormSheet(hrService: hrService),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<List<BenefitModel>>(
            stream: hrService.watchBenefits(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _C.gold, strokeWidth: 2));
              }
              final benefits = snap.data ?? [];
              if (benefits.isEmpty) {
                return const _EmptyState(
                  icon: Icons.card_giftcard_outlined,
                  message: 'Nenhum benefício cadastrado.',
                );
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: benefits.length,
                itemBuilder: (_, i) => _BenefitCard(
                  benefit:   benefits[i],
                  hrService: hrService,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final BenefitModel benefit;
  final HrService hrService;
  const _BenefitCard({required this.benefit, required this.hrService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: benefit.isActive ? _C.border : _C.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: benefit.isActive ? _C.goldDim : _C.redDim,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _benefitIcon(benefit.type),
              color: benefit.isActive ? _C.gold : _C.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(benefit.name,
                    style: const TextStyle(color: _C.tx, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(benefit.typeLabel,
                    style: const TextStyle(color: _C.tx3, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: benefit.isActive,
            onChanged: (v) => hrService.toggleBenefit(benefit.id, v),
            activeThumbColor: _C.green,
            inactiveThumbColor: _C.tx3,
            inactiveTrackColor: _C.s3,
          ),
        ],
      ),
    );
  }

  IconData _benefitIcon(BenefitType type) => switch (type) {
        BenefitType.vt            => Icons.directions_bus_rounded,
        BenefitType.vr            => Icons.restaurant_rounded,
        BenefitType.health        => Icons.local_hospital_rounded,
        BenefitType.dental        => Icons.medical_services_rounded,
        BenefitType.lifeInsurance => Icons.shield_rounded,
        BenefitType.other         => Icons.card_giftcard_rounded,
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// ABA 3 — CARGOS
// ═════════════════════════════════════════════════════════════════════════════
class _JobRolesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<JobRoleController>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _AddBtn(
              label: 'Novo cargo',
              onTap: () => _showJobRoleForm(context, ctrl),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (ctrl.isLoading)
          const LinearProgressIndicator(backgroundColor: _C.s2, color: _C.gold),
        Expanded(
          child: ctrl.roles.isEmpty
              ? const _EmptyState(
                  icon: Icons.work_outline_rounded,
                  message: 'Nenhum cargo cadastrado.',
                )
              : ListView.separated(
                  itemCount: ctrl.roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _JobRoleCard(
                    role: ctrl.roles[i],
                    onEdit: () => _showJobRoleForm(context, ctrl, ctrl.roles[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showJobRoleForm(BuildContext context, JobRoleController ctrl,
      [JobRoleModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.s1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _JobRoleFormSheet(ctrl: ctrl, existing: existing),
    );
  }
}

class _JobRoleCard extends StatelessWidget {
  final JobRoleModel role;
  final VoidCallback onEdit;
  const _JobRoleCard({required this.role, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _C.goldDim,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.work_rounded, color: _C.gold, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.title,
                    style: const TextStyle(color: _C.tx, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(role.sector,
                    style: const TextStyle(color: _C.tx3, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R\$ ${role.hourlyRate.toStringAsFixed(2)}/h',
                  style: const TextStyle(color: _C.gold, fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('valor hora M.O.',
                  style: TextStyle(color: _C.tx3, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 14),
          if (role.requirements.isNotEmpty)
            _InfoChipSmall(label: '${role.requirements.length} req.'),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16, color: _C.tx3),
            style: IconButton.styleFrom(
              backgroundColor: _C.s2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              padding: const EdgeInsets.all(7),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOGS & SHEETS
// ═════════════════════════════════════════════════════════════════════════════

// ─── Dismiss Dialog ───────────────────────────────────────────────────────────
class _DismissDialog extends StatelessWidget {
  final EmployeeModel employee;
  final HrService hrService;
  const _DismissDialog({required this.employee, required this.hrService});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.s1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        SizedBox(width: 10),
        Text('Registrar Desligamento',
            style: TextStyle(color: _C.tx, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.s2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: _C.redDim,
                child: Text(employee.initials,
                    style: const TextStyle(color: _C.red, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(employee.name,
                    style: const TextStyle(color: _C.tx, fontWeight: FontWeight.w600)),
                Text('${employee.jobTitle} · ${employee.sector}',
                    style: const TextStyle(color: _C.tx3, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.orange.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: _C.orange, size: 15),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O colaborador não será excluído. Status alterado para "Desligado" e removido das equipes e benefícios ativos.',
                  style: TextStyle(color: _C.orange, fontSize: 11),
                ),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _C.tx3)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.red,
            foregroundColor: _C.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.exit_to_app_rounded, size: 15),
          label: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () async {
            Navigator.pop(context);
            await hrService.dismissEmployee(employee.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${employee.name} foi desligado(a).'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
      ],
    );
  }
}

// ─── Raise Dialog ─────────────────────────────────────────────────────────────
class _RaiseDialog extends StatefulWidget {
  final EmployeeModel employee;
  final HrService hrService;
  const _RaiseDialog({required this.employee, required this.hrService});

  @override
  State<_RaiseDialog> createState() => _RaiseDialogState();
}

class _RaiseDialogState extends State<_RaiseDialog> {
  final _salaryCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  double get _newSalary => double.tryParse(_salaryCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _diff      => _newSalary - widget.employee.baseSalary;
  double get _pct       => widget.employee.baseSalary > 0 ? (_diff / widget.employee.baseSalary * 100) : 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.s1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Reajuste — ${widget.employee.name}',
          style: const TextStyle(color: _C.tx, fontSize: 15, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salário atual: ${_brl.format(widget.employee.baseSalary)}',
                style: const TextStyle(color: _C.tx2, fontSize: 12)),
            const SizedBox(height: 14),
            _FormField(
              label: 'Novo salário (R\$)',
              controller: _salaryCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _FormField(
              label: 'Motivo',
              controller: _reasonCtrl,
              hint: 'Ex: Reajuste anual, promoção...',
            ),
            if (_newSalary > 0 && _diff != 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _diff > 0 ? _C.greenDim : _C.redDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(_diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: _diff > 0 ? _C.green : _C.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_diff > 0 ? '+' : ''}${_brl.format(_diff)} (${_pct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: _diff > 0 ? _C.green : _C.red,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _C.tx3)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.green,
            foregroundColor: _C.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saving || _newSalary <= 0
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.hrService.applyRaise(
                    employeeId:    widget.employee.id,
                    currentSalary: widget.employee.baseSalary,
                    newSalary:     _newSalary,
                    reason:        _reasonCtrl.text.trim(),
                    updatedBy:     'current_user',
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg))
              : const Text('Aplicar reajuste', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── Assign Benefit Sheet ─────────────────────────────────────────────────────
class _AssignBenefitSheet extends StatefulWidget {
  final EmployeeModel employee;
  final HrService hrService;
  const _AssignBenefitSheet({required this.employee, required this.hrService});

  @override
  State<_AssignBenefitSheet> createState() => _AssignBenefitSheetState();
}

class _AssignBenefitSheetState extends State<_AssignBenefitSheet> {
  BenefitModel? _selected;
  final _valueCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Associar benefício — ${widget.employee.name}',
              style: const TextStyle(color: _C.tx, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          StreamBuilder<List<BenefitModel>>(
            stream: widget.hrService.watchBenefits(onlyActive: true),
            builder: (_, snap) {
              final benefits = snap.data ?? [];
              return Wrap(
                spacing: 8, runSpacing: 8,
                children: benefits.map((b) {
                  final sel = _selected?.id == b.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = sel ? null : b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color:  sel ? _C.goldDim : _C.s2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? _C.goldBdr : _C.border2),
                      ),
                      child: Text(b.name,
                          style: TextStyle(
                            color: sel ? _C.gold2 : _C.tx2,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_selected != null) ...[
            const SizedBox(height: 14),
            _FormField(
              label: 'Valor mensal (R\$)',
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                foregroundColor: _C.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _selected == null || _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final value = double.tryParse(
                              _valueCtrl.text.replaceAll(',', '.')) ??
                          0;
                      await widget.hrService.assignBenefit(
                        EmployeeBenefitModel(
                          id:           '',
                          employeeId:   widget.employee.id,
                          benefitId:    _selected!.id,
                          benefitName:  _selected!.name,
                          monthlyValue: value,
                          startDate:    DateTime.now(),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg))
                  : const Text('Associar benefício',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Employee Form Sheet ──────────────────────────────────────────────────────
class _EmployeeFormSheet extends StatefulWidget {
  final HrService hrService;
  final EmployeeModel? existing;
  const _EmployeeFormSheet({required this.hrService, this.existing});

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _phone    = TextEditingController();
  final _jobTitle = TextEditingController();
  final _sector   = TextEditingController();
  final _salary   = TextEditingController();
  final _cpf      = TextEditingController();
  final _ctps     = TextEditingController();
  final _eduLevel = TextEditingController();
  final _courses  = TextEditingController();
  DateTime _admission = DateTime.now();
  EmployeeRole _role     = EmployeeRole.funcionario;
  EmployeeStatus _status = EmployeeStatus.ativo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text     = e.name;
      _email.text    = e.email;
      _phone.text    = e.phone;
      _jobTitle.text = e.jobTitle;
      _sector.text   = e.sector;
      _salary.text   = e.baseSalary.toStringAsFixed(2);
      _cpf.text      = e.cpf;
      _ctps.text     = e.ctps;
      _eduLevel.text = e.educationLevel;
      _courses.text  = e.courses;
      _admission     = e.admissionDate;
      _role          = e.role;
      _status        = e.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Editar colaborador' : 'Novo colaborador',
                style: const TextStyle(color: _C.tx, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Dados pessoais
            _SectionLabel('Dados pessoais'),
            _Row2(
              _FormField(label: 'Nome completo', controller: _name),
              _FormField(label: 'E-mail', controller: _email, keyboardType: TextInputType.emailAddress),
            ),
            _Row2(
              _FormField(label: 'Telefone', controller: _phone, keyboardType: TextInputType.phone),
              _FormField(label: 'CPF', controller: _cpf, hint: '000.000.000-00'),
            ),
            _FormField(label: 'CTPS', controller: _ctps, hint: 'Número da carteira de trabalho'),

            const SizedBox(height: 12),
            _SectionLabel('Dados contratuais'),
            _Row2(
              _FormField(label: 'Cargo', controller: _jobTitle),
              _FormField(label: 'Setor', controller: _sector),
            ),
            _Row2(
              _FormField(label: 'Salário base (R\$)', controller: _salary,
                  keyboardType: TextInputType.number),
              _DateField(
                label: 'Data de admissão',
                value: _admission,
                onChanged: (d) => setState(() => _admission = d),
              ),
            ),

            // Nível e status
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _DropdownField<EmployeeRole>(
                label: 'Nível',
                value: _role,
                items: EmployeeRole.values,
                itemLabel: (r) => switch(r) {
                  EmployeeRole.funcionario => 'Funcionário',
                  EmployeeRole.supervisor  => 'Supervisor',
                  EmployeeRole.coordenador => 'Coordenador',
                },
                onChanged: (v) => setState(() => _role = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DropdownField<EmployeeStatus>(
                label: 'Status',
                value: _status,
                items: EmployeeStatus.values,
                itemLabel: (s) => switch(s) {
                  EmployeeStatus.ativo     => 'Ativo',
                  EmployeeStatus.ferias    => 'Férias',
                  EmployeeStatus.afastado  => 'Afastado',
                  EmployeeStatus.desligado => 'Desligado',
                },
                onChanged: (v) => setState(() => _status = v!),
              )),
            ]),

            const SizedBox(height: 12),
            _SectionLabel('Formação'),
            _FormField(label: 'Escolaridade', controller: _eduLevel,
                hint: 'Ex: Ensino médio completo'),
            _FormField(label: 'Cursos / Certificações', controller: _courses,
                hint: 'Ex: NR-35, NR-18...'),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.gold,
                  foregroundColor: _C.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg))
                    : Text(isEdit ? 'Salvar alterações' : 'Cadastrar colaborador',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final model = EmployeeModel(
      id:             widget.existing?.id ?? '',
      name:           _name.text.trim(),
      email:          _email.text.trim(),
      phone:          _phone.text.trim(),
      jobTitle:       _jobTitle.text.trim(),
      sector:         _sector.text.trim(),
      role:           _role,
      status:         _status,
      admissionDate:  _admission,
      cpf:            _cpf.text.trim(),
      ctps:           _ctps.text.trim(),
      baseSalary:     double.tryParse(_salary.text.replaceAll(',', '.')) ?? 0,
      educationLevel: _eduLevel.text.trim(),
      courses:        _courses.text.trim(),
      createdAt:      widget.existing?.createdAt ?? now,
      updatedAt:      now,
    );

    if (widget.existing != null) {
      await widget.hrService.updateEmployee(model);
    } else {
      await widget.hrService.addEmployee(model);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ─── Benefit Form Sheet ───────────────────────────────────────────────────────
class _BenefitFormSheet extends StatefulWidget {
  final HrService hrService;
  const _BenefitFormSheet({required this.hrService});

  @override
  State<_BenefitFormSheet> createState() => _BenefitFormSheetState();
}

class _BenefitFormSheetState extends State<_BenefitFormSheet> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  BenefitType _type = BenefitType.other;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Novo benefício',
              style: TextStyle(color: _C.tx, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _FormField(label: 'Nome do benefício', controller: _name,
              hint: 'Ex: Vale Refeição'),
          const SizedBox(height: 10),
          _DropdownField<BenefitType>(
            label: 'Tipo',
            value: _type,
            items: BenefitType.values,
            itemLabel: (t) => switch(t) {
              BenefitType.vt            => 'Vale Transporte',
              BenefitType.vr            => 'Vale Refeição',
              BenefitType.health        => 'Plano de Saúde',
              BenefitType.dental        => 'Plano Odontológico',
              BenefitType.lifeInsurance => 'Seguro de Vida',
              BenefitType.other         => 'Outro',
            },
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 10),
          _FormField(label: 'Descrição (opcional)', controller: _desc),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                foregroundColor: _C.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                await widget.hrService.addBenefit(BenefitModel(
                  id:          '',
                  name:        _name.text.trim(),
                  type:        _type,
                  description: _desc.text.trim(),
                  createdAt:   DateTime.now(),
                ));
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg))
                  : const Text('Cadastrar benefício',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job Role Form Sheet ──────────────────────────────────────────────────────
class _JobRoleFormSheet extends StatefulWidget {
  final JobRoleController ctrl;
  final JobRoleModel? existing;
  const _JobRoleFormSheet({required this.ctrl, this.existing});

  @override
  State<_JobRoleFormSheet> createState() => _JobRoleFormSheetState();
}

class _JobRoleFormSheetState extends State<_JobRoleFormSheet> {
  final _title    = TextEditingController();
  final _sector   = TextEditingController();
  final _desc     = TextEditingController();
  final _hourly   = TextEditingController();
  final _reqCtrl  = TextEditingController();
  List<String> _requirements = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text  = e.title;
      _sector.text = e.sector;
      _desc.text   = e.description;
      _hourly.text = e.hourlyRate.toStringAsFixed(2);
      _requirements = List.from(e.requirements);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing != null ? 'Editar cargo' : 'Novo cargo',
                style: const TextStyle(color: _C.tx, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _Row2(
              _FormField(label: 'Título do cargo', controller: _title),
              _FormField(label: 'Setor', controller: _sector),
            ),
            _Row2(
              _FormField(label: 'Valor hora M.O. (R\$)', controller: _hourly,
                  keyboardType: TextInputType.number),
              const SizedBox.shrink(),
            ),
            _FormField(label: 'Descrição', controller: _desc),
            const SizedBox(height: 10),
            // Requisitos
            const Text('Requisitos', style: TextStyle(color: _C.tx3, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: _FormField(
                  label: 'Adicionar requisito',
                  controller: _reqCtrl,
                  hint: 'Ex: NR-35, 2 anos de experiência...',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final val = _reqCtrl.text.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      _requirements.add(val);
                      _reqCtrl.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_circle_rounded, color: _C.gold),
              ),
            ]),
            if (_requirements.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _requirements.map((r) => _ReqChip(
                  label: r,
                  onRemove: () => setState(() => _requirements.remove(r)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.gold,
                  foregroundColor: _C.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg))
                    : Text(widget.existing != null ? 'Salvar cargo' : 'Cadastrar cargo',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final role = JobRoleModel(
      id:           widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title:        _title.text.trim(),
      sector:       _sector.text.trim(),
      description:  _desc.text.trim(),
      hourlyRate:   double.tryParse(_hourly.text.replaceAll(',', '.')) ?? 0,
      requirements: _requirements,
      isActive:     widget.existing?.isActive ?? true,
      createdAt:    widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing != null) {
      await widget.ctrl.updateRole(role);
    } else {
      await widget.ctrl.addRole(role);
    }

    if (mounted) Navigator.pop(context);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═════════════════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$count', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final EmployeeStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EmployeeStatus.ativo     => ('Ativo',     _C.green),
      EmployeeStatus.ferias    => ('Férias',    _C.blue),
      EmployeeStatus.afastado  => ('Afastado',  _C.orange),
      EmployeeStatus.desligado => ('Desligado', _C.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final EmployeeBenefitModel benefit;
  const _BenefitChip({required this.benefit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _C.blueDim,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _C.blue.withValues(alpha: 0.2)),
    ),
    child: Text(
      '${benefit.benefitName} · ${_brl.format(benefit.monthlyValue)}',
      style: const TextStyle(color: _C.blue, fontSize: 11),
    ),
  );
}

class _SalaryHistoryTile extends StatelessWidget {
  final SalaryHistoryModel history;
  const _SalaryHistoryTile({required this.history});

  @override
  Widget build(BuildContext context) {
    final up = history.newSalary >= history.previousSalary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12, color: up ? _C.green : _C.red),
        const SizedBox(width: 6),
        Text(_brl.format(history.newSalary),
            style: TextStyle(color: up ? _C.green : _C.red,
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text('(${history.percentualAumento.toStringAsFixed(1)}%)',
            style: const TextStyle(color: _C.tx3, fontSize: 11)),
        const Spacer(),
        Text(_date.format(history.effectiveDate),
            style: const TextStyle(color: _C.tx3, fontSize: 11)),
        if (history.reason.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('· ${history.reason}',
              style: const TextStyle(color: _C.tx3, fontSize: 11)),
        ],
      ]),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.tx3, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: _C.tx2, fontSize: 12)),
    ]),
  );
}

class _InfoChipSmall extends StatelessWidget {
  final String label;
  const _InfoChipSmall({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _C.s2,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _C.border2),
    ),
    child: Text(label, style: const TextStyle(color: _C.tx3, fontSize: 10)),
  );
}

class _ReqChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ReqChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
    decoration: BoxDecoration(
      color: _C.s2,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _C.border2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: _C.tx2, fontSize: 11)),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: onRemove,
        child: const Icon(Icons.close_rounded, size: 13, color: _C.tx3),
      ),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _C.s2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Icon(icon, color: _C.tx3, size: 24),
      ),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: _C.tx3, fontSize: 13)),
    ]),
  );
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: const TextStyle(color: _C.tx, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.tx3),
      prefixIcon: const Icon(Icons.search_rounded, color: _C.tx3, size: 18),
      filled: true,
      fillColor: _C.s1,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _C.gold),
      ),
    ),
  );
}

class _TabFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabFilter({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? _C.goldDim : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? _C.goldBdr : _C.border2),
      ),
      child: Text(label,
          style: TextStyle(
            color: selected ? _C.gold : _C.tx3,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
    ),
  );
}

class _AddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _C.goldDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.goldBdr),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, size: 15, color: _C.gold),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            color: _C.gold2, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const _FormField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.tx3, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      TextField(
        controller:   controller,
        keyboardType: keyboardType,
        onChanged:    onChanged,
        style: const TextStyle(color: _C.tx, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _C.tx3, fontSize: 12),
          filled: true,
          fillColor: _C.s2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.gold),
          ),
        ),
      ),
    ]),
  );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.tx3, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate:  DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(primary: _C.gold),
              ),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _C.s2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: _C.tx3),
            const SizedBox(width: 8),
            Text(_date.format(value),
                style: const TextStyle(color: _C.tx, fontSize: 13)),
          ]),
        ),
      ),
    ]),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.tx3, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        dropdownColor: _C.s2,
        style: const TextStyle(color: _C.tx, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: _C.s2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.gold),
          ),
        ),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item)),
        )).toList(),
      ),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label.toUpperCase(),
        style: const TextStyle(color: _C.tx3, fontSize: 9,
            fontWeight: FontWeight.w700, letterSpacing: 1.0)),
  );
}

class _Row2 extends StatelessWidget {
  final Widget left, right;
  const _Row2(this.left, this.right);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );
}