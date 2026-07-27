import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/navigation/navigation_access_policy.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

void main() {
  const modules = [
    NavigationModule(
      index: 0,
      title: 'Granith ERP',
      section: 'Inicio',
      icon: Icons.dashboard_rounded,
      aliases: 'home',
    ),
    NavigationModule(
      index: 1,
      title: 'Projetos',
      section: 'Operacional',
      icon: Icons.business_rounded,
      aliases: 'obras',
    ),
    NavigationModule(
      index: 5,
      title: 'Recursos Humanos',
      section: 'Recursos Humanos',
      icon: Icons.badge_rounded,
      aliases: 'rh',
    ),
    NavigationModule(
      index: 17,
      title: 'Financeiro',
      section: 'Financeiro',
      icon: Icons.account_balance_rounded,
      aliases: 'caixa',
    ),
    NavigationModule(
      index: 21,
      title: 'Acessos',
      section: 'Administrativo',
      icon: Icons.admin_panel_settings_rounded,
      aliases: 'usuarios',
    ),
    NavigationModule(
      index: 29,
      title: 'Tarefas',
      section: 'Operacional',
      icon: Icons.task_alt_rounded,
      aliases: 'atividades',
    ),
  ];

  test('filtra modulos conforme as permissoes do colaborador', () {
    const user = UserModel(
      uid: 'employee-1',
      email: 'obra@granith.com',
      permissions: ['projects.read', 'financial.read'],
    );

    final available = NavigationAccessPolicy.availableModules(modules, user);

    expect(
      available.map((module) => module.index),
      orderedEquals([0, 1, 17, 29]),
    );
  });

  test('mantem todos os modulos para admin e perfil legado sem permissoes', () {
    const admin = UserModel(
      uid: 'admin-1',
      email: 'admin@granith.com',
      role: UserRole.admin,
    );
    const legacyEmployee = UserModel(
      uid: 'employee-1',
      email: 'legado@granith.com',
    );

    expect(
      NavigationAccessPolicy.availableModules(modules, admin),
      hasLength(modules.length),
    );
    expect(
      NavigationAccessPolicy.availableModules(modules, legacyEmployee),
      hasLength(modules.length),
    );
  });
}
