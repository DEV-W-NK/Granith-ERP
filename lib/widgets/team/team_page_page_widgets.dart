import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

class TeamPageView extends StatefulWidget {
  const TeamPageView({super.key});

  @override
  State<TeamPageView> createState() => _TeamPageViewState();
}

class _TeamPageViewState extends State<TeamPageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body:
              controller.teams.isEmpty
                  ? const Center(
                    child: Text(
                      'Nenhuma equipe cadastrada.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.teams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final team = controller.teams[index];
                      final members = controller.getMembersOfTeam(team);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${members.length} membro(s)',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }
}
