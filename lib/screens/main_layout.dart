import 'package:flutter/material.dart';
import 'package:project_granith/screens/projects_page.dart';
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
    const HomePage(),
    const ProjectsPage(), // ← Nova tela adicionada
    const Placeholder(), // Orçamentos
    const Placeholder(), // Estoque
    const Placeholder(), // Financeiro
    const Placeholder(), // Relatórios
    const Placeholder(), // Configurações
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
            Expanded(
              child: pages[selectedIndex],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Granith ERP'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
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
}