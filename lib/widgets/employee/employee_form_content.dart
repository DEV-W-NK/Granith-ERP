import 'package:flutter/material.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class EmployeeFormContent extends StatefulWidget {
  final EmployeeModel? employee;
  final bool isPage;

  const EmployeeFormContent({super.key, this.employee, this.isPage = false});

  @override
  State<EmployeeFormContent> createState() => _EmployeeFormContentState();
}

class _EmployeeFormContentState extends State<EmployeeFormContent> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _coursesController = TextEditingController();
  
  EmployeeRole _role = EmployeeRole.funcionario;
  String _selectedSector = 'Obras';

  final List<String> _sectors = [
    'Obras',
    'Engenharia',
    'Financeiro',
    'Administrativo',
    'RH',
    'Suprimentos',
    'Vendas'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _jobTitleController.text = widget.employee!.jobTitle;
      _salaryController.text = widget.employee!.baseSalary.toString();
      _role = widget.employee!.role;
      _selectedSector = _sectors.contains(widget.employee!.sector) 
          ? widget.employee!.sector 
          : _sectors.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Dados Pessoais', Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(_nameController, 'Nome Completo', Icons.badge),
          
          const SizedBox(height: 32),
          _buildSection('Contratual & RH', Icons.work_outline),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedSector,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Setor', Icons.business_rounded),
                  items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSector = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTextField(_jobTitleController, 'Cargo', Icons.engineering),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_salaryController, 'Salário (R\$)', Icons.attach_money),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<EmployeeRole>(
                  value: _role,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nível Hierárquico', Icons.layers),
                  items: EmployeeRole.values.map((r) => DropdownMenuItem(
                    value: r, 
                    child: Text(r.name.toUpperCase(), style: const TextStyle(fontSize: 12))
                  )).toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildSection('Qualificação', Icons.school_outlined),
          const SizedBox(height: 16),
          _buildTextField(_coursesController, 'Cursos e Certificações', Icons.card_membership, maxLines: 3),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Simulação: Colaborador do setor $_selectedSector cadastrado!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('FINALIZAR CADASTRO', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 20),
        const SizedBox(width: 12),
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.accentGold), borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
    );
  }
}