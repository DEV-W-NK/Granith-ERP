import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports dos componentes que você já possui
import 'package:project_granith/widgets/financial/FinancialFilterBar.dart';
import 'package:project_granith/widgets/financial/FinancialStatCard.dart';
import 'package:project_granith/widgets/financial/TransactionListItem.dart';
import 'package:project_granith/widgets/financial/transactionformdialog.dart';

// Imports de controle e modelos
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class FinancialPageView extends StatefulWidget {
  const FinancialPageView({super.key});

  @override
  State<FinancialPageView> createState() => _FinancialPageViewState();
}

class _FinancialPageViewState extends State<FinancialPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FinancialController>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDesktop),
                  const SizedBox(height: 24),
                  _buildStatCards(ctrl),
                  const SizedBox(height: 20),
                  const FinancialFilterBar(),
                  const SizedBox(height: 16),
                  _buildTabBar(isDesktop),
                  const SizedBox(height: 14),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _TransactionList(transactions: ctrl.transactions),
                        _TransactionList(
                          transactions: ctrl.transactions
                              .where((t) => t.type == TransactionType.income)
                              .toList(),
                        ),
                        _TransactionList(
                          transactions: ctrl.transactions
                              .where((t) => t.type == TransactionType.expense)
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: AppColors.accentGold,
              child: const Icon(Icons.add, color: AppColors.primaryDark),
              onPressed: () => TransactionFormDialog.show(context),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestão Financeira',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Fluxo de caixa, contas a pagar e receber',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => TransactionFormDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: const Icon(Icons.add, color: AppColors.primaryDark, size: 18),
            label: const Text(
              'Nova Transação',
              style: TextStyle(
                  color: AppColors.primaryDark, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCards(FinancialController ctrl) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FinancialStatCard(
            title: 'Saldo em caixa',
            value: ctrl.balance,
            icon: Icons.account_balance_wallet_outlined,
            color: ctrl.balance >= 0 ? AppColors.accentBlue : AppColors.accentRed,
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Receitas recebidas',
            value: ctrl.totalIncome,
            icon: Icons.arrow_upward,
            color: AppColors.accentGreen,
            onTap: () => _tabController.animateTo(1),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Despesas pagas',
            value: ctrl.totalExpense,
            icon: Icons.arrow_downward,
            color: AppColors.accentRed,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'A pagar (pendente)',
            value: ctrl.totalPendingExpense,
            icon: Icons.schedule_outlined,
            color: Colors.orangeAccent,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Vencidos',
            value: ctrl.totalOverdueExpense,
            icon: Icons.warning_amber_rounded,
            color: AppColors.accentRed,
            badgeCount: ctrl.overdueTransactions.length,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'A receber',
            value: ctrl.totalPendingIncome,
            icon: Icons.hourglass_bottom_outlined,
            color: Colors.lightGreenAccent,
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDesktop) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentGold,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        isScrollable: !isDesktop,
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Entradas'),
          Tab(text: 'Saídas'),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<FinancialTransactionModel> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: AppColors.textMuted.withOpacity(0.2),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma movimentação encontrada',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (_, i) => TransactionListItem(transaction: transactions[i]),
    );
  }
}