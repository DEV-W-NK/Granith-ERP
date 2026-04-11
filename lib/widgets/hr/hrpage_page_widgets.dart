import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ViewModels e Controllers
import 'package:project_granith/viewmodels/HrViewmodel.dart';
import 'package:project_granith/controllers/team_controller.dart';

// Models e Services
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/services/HrService.dart';

// Temas e Componentes Internos
import 'package:project_granith/themes/app_theme.dart';

// Note: Assumi que as abas internas (_EmployeesTab, etc) serão mantidas 
// como componentes privados neste arquivo ou movidas para arquivos próprios.

class HrPageView extends StatefulWidget {
  const HrPageView({super.key});

  @override
  State<HrPageView> createState() => _HrPageViewState();
}

class _HrPageViewState extends State<HrPageView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HrService _hrService = HrService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Inicializa os controllers necessários
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamController>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return ChangeNotifierProvider(
      create: (_) => HrViewModel(_hrService),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Padding(
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HrHeader(hrService: _hrService),
              const SizedBox(height: 20),
              _HrTabBar(tabController: _tabController),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Componentes de abas (os que você definiu no código original)
                    // _EmployeesTab(hrService: _hrService),
                    // _BenefitsTab(hrService: _hrService),
                    // _JobRolesTab(),
                    const Center(child: Text("Lista de Colaboradores", style: TextStyle(color: Colors.white))),
                    const Center(child: Text("Gestão de Benefícios", style: TextStyle(color: Colors.white))),
                    const Center(child: Text("Configuração de Cargos", style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── COMPONENTES PRIVADOS ───────────────────────────────────────────────────

class _HrHeader extends StatelessWidget {
  final HrService hrService;
  const _HrHeader({required this.hrService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EmployeeModel>>(
      stream: hrService.watchEmployees(),
      builder: (context, snap) {
        final employees = snap.data ?? [];
        final ativos = employees.where((e) => e.isActive).length;
        final ferias = employees.where((e) => e.isOnLeave).length;
        final deslig = employees.where((e) => e.isDismissed).length;

        return Row(
          children: [
            _HeaderIcon(),
            const SizedBox(width: 14),
            const _HeaderTitle(),
            _StatPill(label: 'Ativos', count: ativos, color: AppColors.accentGreen),
            const SizedBox(width: 8),
            _StatPill(label: 'Férias', count: ferias, color: AppColors.accentBlue),
            const SizedBox(width: 8),
            _StatPill(label: 'Desligados', count: deslig, color: AppColors.accentRed),
          ],
        );
      },
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: const Icon(Icons.people_alt_rounded, color: AppColors.accentGold, size: 20),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestão de RH',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17,
                  fontWeight: FontWeight.w600, letterSpacing: -0.3)),
          SizedBox(height: 2),
          Text('Colaboradores, benefícios e cargos',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HrTabBar extends StatelessWidget {
  final TabController tabController;
  const _HrTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: AppColors.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.people_rounded, size: 16), text: 'Colaboradores'),
          Tab(icon: Icon(Icons.card_giftcard_rounded, size: 16), text: 'Benefícios'),
          Tab(icon: Icon(Icons.work_rounded, size: 16), text: 'Cargos'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$count', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
    ]),
  );
}