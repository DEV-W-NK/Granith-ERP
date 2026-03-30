import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class JobRoleRegistrationPage extends StatefulWidget {
  const JobRoleRegistrationPage({super.key});

  @override
  State<JobRoleRegistrationPage> createState() => _JobRoleRegistrationPageState();
}

class _JobRoleRegistrationPageState extends State<JobRoleRegistrationPage> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _hourlyCtrl   = TextEditingController(); // era _salaryController
  final _descCtrl     = TextEditingController();
  String _selectedSector = 'Obras';

  final List<String> _sectors = [
    'Obras', 'Engenharia', 'Financeiro', 'Administrativo', 'RH', 'Vendas'
  ];

  @override
  Widget build(BuildContext context) {
    final controller  = context.watch<JobRoleController>();
    final isDesktop   = MediaQuery.of(context).size.width > 900;
    final hourlyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel esquerdo — lista de cargos
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.roles.length,
                      itemBuilder: (_, i) =>
                          _buildRoleCard(controller.roles[i], hourlyFormat),
                    ),
                  ),
                ],
              ),
            ),

            if (isDesktop) const SizedBox(width: 32),

            // Painel direito — formulário (só desktop)
            if (isDesktop)
              Expanded(
                flex: 2,
                child: _buildFormPanel(controller),
              ),
          ],
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: AppColors.accentGold,
              onPressed: () => _showMobileForm(context, controller),
              child: const Icon(Icons.add, color: AppColors.primaryDark),
            )
          : null,
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Cargos e Funções',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      Text(
        'Defina a hierarquia e o valor-hora de cada função.',
        style: TextStyle(color: AppColors.textMuted),
      ),
    ],
  );

  // ── Card do cargo ──────────────────────────────────────────────────────────
  Widget _buildRoleCard(JobRoleModel role, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.work_outline, color: AppColors.accentGold),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              // FIX: role.baseSalary → role.hourlyRate + label "valor/h"
              Text('${role.sector} • ${fmt.format(role.hourlyRate)}/h',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (role.requirements.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(role.requirements.join(' · '),
                      style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 11)),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
          onPressed: () {},
        ),
      ]),
    );
  }

  // ── Formulário ─────────────────────────────────────────────────────────────
  Widget _buildFormPanel(JobRoleController controller) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cadastrar Novo Cargo',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(_titleCtrl, 'Título do Cargo', Icons.title),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSector,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Setor', Icons.business),
              items: _sectors
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSector = v!),
            ),
            const SizedBox(height: 16),
            // FIX: campo renomeado para Valor Hora (M.O.) — não é mais salário fixo
            _buildField(_hourlyCtrl, 'Valor Hora M.O. (R\$)',
                Icons.timer_outlined,
                isNumber: true,
                hint: 'Ex: 28.50'),
            const SizedBox(height: 16),
            _buildField(_descCtrl, 'Descrição / Responsabilidades',
                Icons.description,
                maxLines: 3),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _save(controller),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold),
                child: const Text('SALVAR CARGO',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines  = 1,
    String? hint,
  }) {
    return TextFormField(
      controller:   ctrl,
      maxLines:     maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration:   _inputDecoration(label, icon, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText:   label,
      hintText:    hint,
      hintStyle:   const TextStyle(color: Colors.white24, fontSize: 12),
      labelStyle:  const TextStyle(color: AppColors.textMuted),
      prefixIcon:  Icon(icon, color: AppColors.textMuted, size: 20),
      enabledBorder: OutlineInputBorder(
          borderSide:   const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderSide:   const BorderSide(color: AppColors.accentGold),
          borderRadius: BorderRadius.circular(12)),
    );
  }

  // ── Salvar ────────────────────────────────────────────────────────────────
  void _save(JobRoleController controller) {
    if (!_formKey.currentState!.validate()) return;

    // FIX: baseSalary removido → hourlyRate obrigatório
    final role = JobRoleModel(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      title:       _titleCtrl.text.trim(),
      sector:      _selectedSector,
      description: _descCtrl.text.trim(),
      hourlyRate:  double.tryParse(
                       _hourlyCtrl.text.replaceAll(',', '.')) ?? 0.0,
      createdAt:   DateTime.now(),
    );

    controller.addRole(role);
    _titleCtrl.clear();
    _hourlyCtrl.clear();
    _descCtrl.clear();
  }

  void _showMobileForm(BuildContext context, JobRoleController controller) {
    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor:  AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
            child: _buildFormPanel(controller)),
      ),
    );
  }
}