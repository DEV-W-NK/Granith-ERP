import 'package:flutter/material.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/mobile_drawer.dart';
import 'home_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomePage(), // Index 0 - Home
    const ProjectsPage(), // Index 1 - Projetos
    const BudgetsPage(), // Index 2 - Orçamentos
    const BudgetTypesPage(), // Index 3 - Tipos de Orçamento
    const SuppliersPage(), // Index 4 - Fornecedores
    _buildPlaceholderPage(
      'Estoque',
      'Controle de materiais e equipamentos',
    ), // Index 5
    _buildPlaceholderPage(
      'Financeiro',
      'Gestão financeira e fluxo de caixa',
    ), // Index 6
    _buildPlaceholderPage(
      'Relatórios',
      'Análises e relatórios detalhados',
    ), // Index 7
    _buildPlaceholderPage(
      'Configurações',
      'Configurações do sistema',
    ), // Index 8
  ];

  // Mapeamento dos títulos das páginas para o AppBar mobile
  final List<String> pageTitles = [
    'Granith ERP',
    'Projetos',
    'Orçamentos',
    'Tipos de Orçamento',
    'Fornecedores',
    'Estoque',
    'Financeiro',
    'Relatórios',
    'Configurações',
  ];

  // Mapeamento dos ícones para cada página
  final List<IconData> pageIcons = [
    Icons.dashboard_rounded,
    Icons.business_rounded,
    Icons.receipt_long_rounded,
    Icons.category_rounded,
    Icons.store_rounded,
    Icons.inventory_rounded,
    Icons.account_balance_rounded,
    Icons.analytics_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SidebarMenu(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                pageIcons[selectedIndex],
                color: AppColors.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                pageTitles[selectedIndex],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          actions: _buildAppBarActions(),
        ),
        drawer: MobileDrawer(
          selectedIndex: selectedIndex,
          onItemSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
            Navigator.pop(context);
          },
        ),
        body: pages[selectedIndex],
      );
    }
  }

  List<Widget>? _buildAppBarActions() {
    switch (selectedIndex) {
      case 3: // Budget Types Page
        return [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
            onPressed: () {
              _showCreateBudgetTypeDialog();
            },
            tooltip: 'Novo Tipo',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              _refreshCurrentPage();
            },
            tooltip: 'Atualizar',
          ),
        ];

      case 2: // Budgets Page
        return [
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // Implementar filtros de orçamentos
            },
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
            onPressed: () {
              // Implementar criação de orçamento
            },
            tooltip: 'Novo Orçamento',
          ),
        ];

      case 1: // Projects Page
        return [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // Implementar busca de projetos
            },
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
            onPressed: () {
              // Implementar criação de projeto
            },
            tooltip: 'Novo Projeto',
          ),
        ];

      case 4: // Suppliers Page
        return [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // Implementar busca de fornecedores
            },
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
            onPressed: () {
              // Implementar criação de fornecedor
            },
            tooltip: 'Novo Fornecedor',
          ),
        ];

      default:
        return null;
    }
  }

  void _showCreateBudgetTypeDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo formulário de novo tipo...'),
        backgroundColor: AppColors.accentGold,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _refreshCurrentPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atualizando dados...'),
        backgroundColor: AppColors.accentBlue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  static Widget _buildPlaceholderPage(String title, String description) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 64,
                color: AppColors.accentGold.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                '$description\n\nEm desenvolvimento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}