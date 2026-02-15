import 'package:flutter/material.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/inventory_page.dart';
import 'package:project_granith/screens/items_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/purchases_page.dart'; // Importada a nova página
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/themes/app_theme.dart';
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
    const HomePage(),        // Index 0
    const ProjectsPage(),    // Index 1
    const BudgetsPage(),     // Index 2
    const BudgetTypesPage(), // Index 3
    const SuppliersPage(),   // Index 4
    const ItemsPage(),       // Index 5
    const PurchasesPage(),   // Index 6 - Nova Página de Compras!
    const InventoryPage(),   // Index 7 - Nova Página de Estoque!
    
    _buildPlaceholderPage(
      'Financeiro',
      'Gestão financeira e fluxo de caixa',
    ), // Index 7
    _buildPlaceholderPage(
      'Relatórios',
      'Análises e relatórios detalhados',
    ), // Index 8
    _buildPlaceholderPage(
      'Configurações',
      'Configurações do sistema',
    ), // Index 9
  ];

  // Títulos para o AppBar Mobile
  final List<String> pageTitles = [
    'Granith ERP',
    'Projetos',
    'Orçamentos',
    'Tipos de Orçamento',
    'Fornecedores',
    'Catálogo de Itens',
    'Compras & Pedidos', // Título para Compras
    'Financeiro',
    'Relatórios',
    'Configurações',
  ];

  // Ícones (usados apenas no AppBar Mobile se SidebarMenu for separado)
  final List<IconData> pageIcons = [
    Icons.dashboard_rounded,
    Icons.business_rounded,
    Icons.receipt_long_rounded,
    Icons.category_rounded,
    Icons.store_rounded,
    Icons.inventory_2_rounded,
    Icons.shopping_cart_rounded, // Ícone para Compras
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
            // Menu Lateral Desktop
            SidebarMenu(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
            // Conteúdo Principal
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      );
    } else {
      // Layout Mobile
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
                  fontSize: 18,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
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

  // Ações específicas para cada página no AppBar Mobile
  List<Widget>? _buildAppBarActions() {
    switch (selectedIndex) {
      case 1: // Projetos
        return [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () {}, // Implementar busca global
          ),
        ];
      
      case 6: // Compras (PurchasesPage)
        // A PurchasesPage já tem suas ações internas, mas se quiser adicionar atalhos globais:
        return [
           // Exemplo: Filtro rápido de status
           IconButton(
            icon: const Icon(Icons.filter_list_alt, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ];

      default:
        return null;
    }
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