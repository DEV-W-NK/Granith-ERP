import 'package:flutter/material.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/HrPage.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/dailyLogsPage.dart';
import 'package:project_granith/screens/inventory_page.dart';
import 'package:project_granith/screens/items_page.dart';
import 'package:project_granith/screens/job_role_registration_page.dart';
import 'package:project_granith/screens/material_requisition_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/purchases_page.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/screens/team_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/seeder.dart';
import 'package:project_granith/widgets/navigation/mobile_drawer.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'home_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

final List<Widget> pages = [
  const HomePage(),                // 0
  const ProjectsPage(),            // 1
  const DailyLogsPage(),           // 2
  const MaterialRequisitionPage(), // 3
  const HrPage(),                  // 4 - CENTRALIZADO (Funcionários, Cargos, Benefícios)
  const BudgetsPage(),             // 5 - (Subiu de posição)
  const BudgetTypesPage(),         // 6
  const SuppliersPage(),           // 7
  const ItemsPage(),               // 8
  const PurchasesPage(),           // 9
  const InventoryPage(),           // 10
  const FinancialPage(),           // 11
  const ReportsPage(),             // 12
  _buildPlaceholderPage('Configurações', 'Em breve'), // 13
];

final List<String> pageTitles = [
  'Granith ERP', 'Projetos', 'Diário de Obras', 'Requisições',
  'Recursos Humanos', // 4
  'Orçamentos', 'Tipos de Orçamento', 'Fornecedores', 
  'Catálogo de Itens', 'Compras & Pedidos', 'Estoque', 
  'Financeiro', 'DRE Gerencial', 'Configurações',
];

final List<IconData> pageIcons = [
  Icons.dashboard_rounded, Icons.business_rounded, Icons.menu_book_rounded, 
  Icons.assignment_rounded, 
  Icons.badge_rounded, // 4 - Ícone de RH
  Icons.receipt_long_rounded, Icons.category_rounded, Icons.store_rounded, 
  Icons.inventory_2_rounded, Icons.shopping_cart_rounded, Icons.warehouse_rounded, 
  Icons.account_balance_rounded, Icons.bar_chart_rounded, Icons.settings_rounded,
];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _runSeeder,
        backgroundColor: AppColors.accentGold,
        tooltip: 'Popular Banco de Dados (Seed)',
        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryDark),
      ),
      body: isDesktop
          ? Row(
              children: [
                SidebarMenu(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) =>
                      setState(() => selectedIndex = index),
                ),
                Expanded(child: pages[selectedIndex]),
              ],
            )
          : Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(pageIcons[selectedIndex],
                        color: AppColors.accentGold, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      pageTitles[selectedIndex],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
              ),
              drawer: MobileDrawer(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() => selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
              body: pages[selectedIndex],
            ),
    );
  }

  static Widget _buildPlaceholderPage(String title, String description) {
    return Center(
      child: Text(
        '$title\n$description',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _runSeeder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Executar Seeder?',
            style: TextStyle(color: AppColors.accentGold)),
        content: const Text(
          'Isso irá criar dados fictícios (Projetos, Orçamentos, etc) no banco de dados.\nDeseja continuar?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, Popular',
                style: TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando Seeder... Isso pode levar alguns segundos.'),
          backgroundColor: AppColors.primaryDark,
          duration: Duration(seconds: 2),
        ),
      );

      try {
        final seeder = DatabaseSeeder();
        final success = await seeder.seed();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Banco de dados populado com sucesso!'
                : 'Erro ao popular banco. Verifique o console.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro crítico: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}