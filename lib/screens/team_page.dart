import 'package:flutter/material.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/employee/employee_form_dialog.dart';
import 'package:provider/provider.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  @override
  void initState() {
    super.initState();
    // Inicia as streams do Firestore
    context.read<TeamController>().init();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TeamController>();
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(isDesktop: isDesktop),
            const SizedBox(height: 32),

            // Mensagem de erro (se houver)
            if (controller.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(controller.error!, style: const TextStyle(color: Colors.red))),
                ]),
              ),

            // Loading overlay durante operações
            if (controller.isLoading) const LinearProgressIndicator(
              backgroundColor: Colors.white12,
              color: AppColors.accentGold,
            ),
            if (controller.isLoading) const SizedBox(height: 8),

            Expanded(
              child: controller.teams.isEmpty
                  ? _EmptyState(onCreateTeam: () => _showCreateTeamDialog(context))
                  : ListView.separated(
                      itemCount: controller.teams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _TeamCard(
                          team: controller.teams[index],
                          controller: controller,
                          onManageMembers: () => _showManageMembersDialog(
                            context, controller.teams[index], controller,
                          ),
                          onEdit: () => _showEditTeamDialog(
                            context, controller.teams[index], controller,
                          ),
                          onDelete: () => _confirmDeleteTeam(
                            context, controller.teams[index], controller,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _TeamFormDialog(
        onSave: (name, description) async {
          await context.read<TeamController>().createTeam(
            name: name,
            description: description,
          );
        },
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, TeamModel team, TeamController controller) {
    showDialog(
      context: context,
      builder: (_) => _TeamFormDialog(
        initialName: team.name,
        initialDescription: team.description,
        onSave: (name, description) async {
          await controller.updateTeam(
            team.copyWith(name: name, description: description, updatedAt: DateTime.now()),
          );
        },
      ),
    );
  }

  void _showManageMembersDialog(
    BuildContext context,
    TeamModel team,
    TeamController controller,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ManageMembersDialog(team: team, controller: controller),
    );
  }

  void _confirmDeleteTeam(BuildContext context, TeamModel team, TeamController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Excluir Equipe', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja excluir a equipe "${team.name}"? Os funcionários não serão removidos.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.deleteTeam(team.id);
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS INTERNOS
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool isDesktop;
  const _Header({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TeamController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestão de Equipes',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Monte equipes com seus funcionários cadastrados',
              style: TextStyle(color: AppColors.textMuted, fontSize: isDesktop ? 16 : 14),
            ),
          ],
        ),
        Row(
          children: [
            // Botão: Novo Funcionário
            OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const EmployeeFormDialog(),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Novo Funcionário'),
            ),
            const SizedBox(width: 12),
            // Botão: Nova Equipe
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _TeamFormDialog(
                  onSave: (name, description) async {
                    await controller.createTeam(name: name, description: description);
                  },
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Nova Equipe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Card de Equipe ─────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final TeamController controller;
  final VoidCallback onManageMembers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.controller,
    required this.onManageMembers,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final members = controller.getMembersOfTeam(team);
    final leader = members.where((e) => e.id == team.leaderId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Ícone lateral ──────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.accentGold, size: 26),
          ),

          const SizedBox(width: 16),

          // ── Bloco central: nome + descrição + meta-info ────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Descrição
                if (team.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    team.description,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Meta-info: membros + líder
                Row(
                  children: [
                    // Contagem
                    Icon(Icons.person_outline_rounded, size: 14, color: Colors.blue.shade300),
                    const SizedBox(width: 3),
                    Text(
                      '${members.length} membro${members.length != 1 ? 's' : ''}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),

                    // Líder
                    if (leader != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          leader.name,
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Ações ───────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onManageMembers,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: BorderSide(color: AppColors.accentGold.withOpacity(0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Gerenciar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                color: AppColors.surfaceDark,
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white38, size: 20),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [
                    Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text('Editar', style: TextStyle(color: Colors.white)),
                  ])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


}



// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTeam;
  const _EmptyState({required this.onCreateTeam});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_rounded, size: 72, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma equipe criada ainda',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie uma equipe e adicione os funcionários cadastrados.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateTeam,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Criar primeira equipe', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog: Criar / Editar Equipe ───────────────────────────────────────────

class _TeamFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final Future<void> Function(String name, String description) onSave;

  const _TeamFormDialog({
    this.initialName,
    this.initialDescription,
    required this.onSave,
  });

  @override
  State<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<_TeamFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Editar Equipe' : 'Nova Equipe',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(controller: _nameCtrl, label: 'Nome da equipe', hint: 'Ex: Equipe Alfa'),
            const SizedBox(height: 16),
            _Field(
              controller: _descCtrl,
              label: 'Descrição (opcional)',
              hint: 'Ex: Responsável pela obra do Residencial Alphaville',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
          ),
          onPressed: _saving || _nameCtrl.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave(_nameCtrl.text.trim(), _descCtrl.text.trim());
                  if (mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}

// ─── Dialog: Gerenciar Membros ────────────────────────────────────────────────

class _ManageMembersDialog extends StatelessWidget {
  final TeamModel team;
  final TeamController controller;

  const _ManageMembersDialog({required this.team, required this.controller});

  @override
  Widget build(BuildContext context) {
    final members = controller.getMembersOfTeam(team);
    final available = controller.getAvailableEmployees(team);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('Gerenciar membros', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.normal)),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            // ── Membros atuais ──────────────────────────────
            _SectionLabel(label: 'Membros da equipe (${members.length})'),
            const SizedBox(height: 8),
            Expanded(
              child: members.isEmpty
                  ? Center(child: Text('Nenhum membro adicionado', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (_, i) {
                        final emp = members[i];
                        final isLeader = emp.id == team.leaderId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentGold.withOpacity(0.2),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(emp.name, style: const TextStyle(color: Colors.white, fontSize: 14))),
                              if (isLeader)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Líder', style: TextStyle(color: AppColors.accentGold, fontSize: 10)),
                                ),
                            ],
                          ),
                          subtitle: Text(emp.jobTitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Definir/remover líder
                              IconButton(
                                icon: Icon(
                                  isLeader ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: isLeader ? AppColors.accentGold : Colors.white38,
                                  size: 20,
                                ),
                                tooltip: isLeader ? 'Remover liderança' : 'Definir como líder',
                                onPressed: () => controller.setLeader(team.id, isLeader ? null : emp.id),
                              ),
                              // Remover da equipe
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20),
                                tooltip: 'Remover da equipe',
                                onPressed: () => controller.removeMember(team.id, emp.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(color: Colors.white12, height: 24),

            // ── Adicionar funcionários ──────────────────────
            _SectionLabel(label: 'Adicionar à equipe'),
            const SizedBox(height: 8),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Text(
                        'Todos os funcionários já fazem parte desta equipe.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (_, i) {
                        final emp = available[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(emp.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text('${emp.jobTitle} · ${emp.sector}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green, size: 20),
                            tooltip: 'Adicionar à equipe',
                            onPressed: () => controller.addMember(team.id, emp.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
    );
  }
}

// ─── Input Field ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}