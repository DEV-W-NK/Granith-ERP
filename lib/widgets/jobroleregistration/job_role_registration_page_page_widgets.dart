import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Controllers e Models
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/models/job_role_model.dart';

// Temas e Componentes Comuns
import 'package:project_granith/themes/app_theme.dart';

class JobRoleRegistrationView extends StatelessWidget {
  const JobRoleRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Esquerdo: Lista de Cargos
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _JobRoleHeader(),
                  const SizedBox(height: 24),
                  const Expanded(child: _JobRoleList()),
                ],
              ),
            ),

            if (isDesktop) ...[
              const SizedBox(width: 32),
              // Painel Direito: Formulário (Fixo no Desktop)
              const Expanded(
                flex: 2,
                child: SingleChildScrollView(child: _JobRoleFormPanel()),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: !isDesktop ? const _MobileAddButton() : null,
    );
  }
}

// ─── COMPONENTES ────────────────────────────────────────────────────────────

class _JobRoleHeader extends StatelessWidget {
  const _JobRoleHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cargos e Funções',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Defina a hierarquia e o valor-hora de cada função.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _JobRoleList extends StatelessWidget {
  const _JobRoleList();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobRoleController>();
    final hourlyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (controller.roles.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum cargo cadastrado.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.roles.length,
      itemBuilder:
          (_, i) => _JobRoleCard(role: controller.roles[i], fmt: hourlyFormat),
    );
  }
}

class _JobRoleCard extends StatelessWidget {
  final JobRoleModel role;
  final NumberFormat fmt;

  const _JobRoleCard({required this.role, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Futura edição
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _RoleIcon(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${role.sector} • ${fmt.format(role.hourlyRate)}/h',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (role.requirements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            role.requirements.join(' · '),
                            style: TextStyle(
                              color: AppColors.textMuted.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: const Icon(
        Icons.work_outline,
        color: AppColors.accentGold,
        size: 22,
      ),
    );
  }
}

class _JobRoleFormPanel extends StatefulWidget {
  const _JobRoleFormPanel();

  @override
  State<_JobRoleFormPanel> createState() => _JobRoleFormPanelState();
}

class _JobRoleFormPanelState extends State<_JobRoleFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _hourlyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedSector = 'Obras';

  final List<String> _sectors = [
    'Obras',
    'Engenharia',
    'Financeiro',
    'Administrativo',
    'RH',
    'Vendas',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hourlyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<JobRoleController>();
    final role = JobRoleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      sector: _selectedSector,
      description: _descCtrl.text.trim(),
      hourlyRate: double.tryParse(_hourlyCtrl.text.replaceAll(',', '.')) ?? 0.0,
      createdAt: DateTime.now(),
    );

    controller.addRole(role);
    _titleCtrl.clear();
    _hourlyCtrl.clear();
    _descCtrl.clear();

    if (MediaQuery.of(context).size.width <= 900) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cargo cadastrado com sucesso!'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cadastrar Novo Cargo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleCtrl, 'Título do Cargo', Icons.title),
            const SizedBox(height: 16),
            _buildSectorDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              _hourlyCtrl,
              'Valor Hora M.O. (R\$)',
              Icons.timer_outlined,
              isNumber: true,
              hint: 'Ex: 28.50',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _descCtrl,
              'Descrição / Responsabilidades',
              Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            _SubmitButton(onPressed: _handleSave),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType:
              isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.backgroundDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
        ),
      ],
    );
  }

  Widget _buildSectorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Setor',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSector,
          dropdownColor: AppColors.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.business,
              color: AppColors.textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.backgroundDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
          ),
          items:
              _sectors
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
          onChanged: (v) => setState(() => _selectedSector = v!),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'SALVAR CARGO',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _MobileAddButton extends StatelessWidget {
  const _MobileAddButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.accentGold,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) => Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 24,
                ),
                child: const SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: _JobRoleFormPanel(),
                  ),
                ),
              ),
        );
      },
      child: const Icon(Icons.add, color: AppColors.primaryDark),
    );
  }
}
