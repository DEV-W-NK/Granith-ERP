import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/viewmodels/materialrequisitionviewmodel.dart';
import 'package:project_granith/models/requisition_model.dart';
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
        ],
      ),
    );
  }
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
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
