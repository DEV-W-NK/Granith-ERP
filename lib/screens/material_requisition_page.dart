import 'package:flutter/material.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/material_requisition/material_requisition_widgets.dart';
import 'package:provider/provider.dart';

class MaterialRequisitionPage extends StatefulWidget {
  const MaterialRequisitionPage({super.key});
  @override
  State<MaterialRequisitionPage> createState() => _MaterialRequisitionPageState();
}

class _MaterialRequisitionPageState extends State<MaterialRequisitionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<MaterialRequisitionController>().init();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MaterialRequisitionController>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MaterialRequisitionHeader(),
            const SizedBox(height: 20),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10))),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentGold,
                labelColor: AppColors.accentGold,
                unselectedLabelColor: AppColors.textMuted,
                dividerColor: Colors.transparent,
                isScrollable: !isDesktop,
                tabs: [
                  Tab(text: 'Todas (${ctrl.requisitions.length})'),
                  Tab(text: 'Pendentes (${ctrl.pendingCount})'),
                  const Tab(text: 'Aprovadas'),
                  const Tab(text: 'Concluídas'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _List(requisitions: ctrl.requisitions),
                        _List(requisitions: ctrl.pending),
                        _List(requisitions: ctrl.approved),
                        _List(requisitions: ctrl.requisitions.where((r) =>
                            r.status == RequisitionStatus.purchased ||
                            r.status == RequisitionStatus.rejected ||
                            r.status == RequisitionStatus.delivered).toList()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<MaterialRequisitionModel> requisitions;
  const _List({required this.requisitions});

  @override
  Widget build(BuildContext context) {
    if (requisitions.isEmpty) return const MaterialRequisitionEmptyState();
    return ListView.builder(
      itemCount: requisitions.length,
      itemBuilder: (_, i) => MaterialRequisitionCard(requisition: requisitions[i]),
    );
  }
}