import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_model.dart';

import '../helpers/fake_project_service.dart';

Future<void> _waitForDebounce() async {
  await Future<void>.delayed(const Duration(milliseconds: 30));
}

void main() {
  group('ProjectsController', () {
    late FakeProjectService service;
    late ProjectsController controller;

    setUp(() {
      service = FakeProjectService(
        initialProjects: [
          Project(
            id: 'p-1',
            name: 'Obra Horizonte',
            client: 'Cliente Azul',
            description: 'Execucao estrutural',
            status: ProjectStatus.inProgress,
            startDate: DateTime(2026, 4, 10),
            budget: 200000,
            currentCost: 45000,
            location: 'Campinas',
            tags: const ['estrutura'],
            teamSize: 10,
          ),
          Project(
            id: 'p-2',
            name: 'Reforma Central',
            client: 'Cliente Verde',
            description: 'Acabamento e retrofit',
            status: ProjectStatus.planning,
            startDate: DateTime(2026, 2, 10),
            budget: 90000,
            currentCost: 10000,
            location: 'Sao Paulo',
            tags: const ['retrofit', 'acabamento'],
            teamSize: 4,
          ),
        ],
      );

      controller = ProjectsController(
        service,
        saveDebounceDelay: const Duration(milliseconds: 5),
        updateDebounceDelay: const Duration(milliseconds: 5),
        deleteDebounceDelay: const Duration(milliseconds: 5),
        searchDebounceDelay: const Duration(milliseconds: 5),
      );
    });

    test('loadProjects carrega e ordena projetos por data de inicio', () async {
      await controller.loadProjects();

      expect(controller.projects, hasLength(2));
      expect(controller.filteredProjects.first.id, 'p-1');
      expect(controller.filteredProjects.last.id, 'p-2');
      expect(controller.hasError, isFalse);
    });

    test('updateSearchQuery filtra por texto apos debounce', () async {
      await controller.loadProjects();

      controller.updateSearchQuery('retrofit');
      await _waitForDebounce();

      expect(controller.filteredProjects, hasLength(1));
      expect(controller.filteredProjects.single.id, 'p-2');
      expect(controller.hasActiveFilters, isTrue);
    });

    test('updateFilter aplica filtro por status', () async {
      await controller.loadProjects();

      controller.updateFilter('inprogress');

      expect(controller.filteredProjects, hasLength(1));
      expect(controller.filteredProjects.single.id, 'p-1');
    });

    test('addProject persiste e atualiza lista local', () async {
      await controller.loadProjects();

      final id = await controller.addProject(
        Project(
          name: 'Nova Torre',
          client: 'Cliente Branco',
          description: 'Nova frente de obra',
          status: ProjectStatus.planning,
          startDate: DateTime(2026, 5, 1),
          budget: 50000,
          currentCost: 0,
          location: 'Sorocaba',
          tags: const ['novo'],
          teamSize: 3,
        ),
      );
      await _waitForDebounce();

      expect(id, 'project-created');
      expect(service.lastAddedProject?.name, 'Nova Torre');
      expect(
        controller.projects.any((project) => project.id == 'project-created'),
        isTrue,
      );
    });

    test('deleteProject remove item da lista local', () async {
      await controller.loadProjects();

      await controller.deleteProject('p-2');
      await _waitForDebounce();

      expect(service.deletedProjectId, 'p-2');
      expect(
        controller.projects.map((item) => item.id),
        isNot(contains('p-2')),
      );
    });
  });
}
